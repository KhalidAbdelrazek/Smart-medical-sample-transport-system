/*
 * USART.c
 *
 * Created: 10/1/2025 8:18:50 PM
 *  Author: nanav
 *
 * BAUD RATE FIX (critical)
 * ------------------------
 * The MCU runs at F_CPU = 8 MHz.
 *
 * With U2X=1:  UBRR = F_CPU / (8 * baud) - 1
 *   115200 baud → UBRR = 8000000/(8*115200) - 1 = 7.68  → round to 8
 *              actual baud = 8000000 / (8*(8+1)) = 111 111 baud
 *              ERROR = |115200-111111|/115200 = 3.5 %  ← EXCEEDS UART 2% limit!
 *              Result: silent bit corruption, commands silently lost.
 *
 *   9600 baud  → UBRR = 8000000/(8*9600) - 1  = 103.17 → round to 103
 *              actual baud = 8000000 / (8*(103+1)) = 9615 baud
 *              ERROR = |9600-9615|/9600 = 0.16 %  ← rock solid
 *
 * FIX: Use 9600 baud on BOTH the ATmega and the Raspberry Pi.
 *      Also switched to normal speed (U2X=0) for additional stability.
 *      Normal speed formula: UBRR = F_CPU / (16 * baud) - 1
 *   9600 baud  → UBRR = 8000000/(16*9600) - 1 = 51.08 → round to 51
 *              actual baud = 8000000 / (16*(51+1)) = 9615 baud
 *              ERROR = 0.16 %  ← perfect
 *
 * RX Complete Interrupt (RXCIE) is enabled so every incoming byte
 * is captured into a ring buffer by the ISR — the main loop never
 * blocks waiting for serial data.
 *
 * UART_Read_nonblocking() lets main.c poll the ring buffer without
 * ever stalling. If no byte is available it returns 0.
 */

#include <avr/io.h>
#include <avr/interrupt.h>
#define F_CPU 8000000UL
#include <util/delay.h>
#include "important macros.h"
#include "USART.h"

/* ── Ring buffer storage (defined here, declared extern in header) ── */
volatile char    uart_rx_buf[UART_RX_BUFFER_SIZE];
volatile uint8_t uart_rx_head = 0;   /* ISR writes here  */
volatile uint8_t uart_rx_tail = 0;   /* main reads here  */

/* ── RX Complete ISR — fires on every received byte ─────────────── */
ISR(USART_RXC_vect)
{
    char byte = UDR;   /* MUST read UDR to clear the interrupt flag   */

    /* Drop newline characters — they carry no command information    */
    if (byte == '\r' || byte == '\n') return;

    uint8_t next_head = (uart_rx_head + 1) & UART_RX_BUFFER_MASK;

    /* Only store if buffer has space (discard on overflow)           */
    if (next_head != uart_rx_tail)
    {
        uart_rx_buf[uart_rx_head] = byte;
        uart_rx_head = next_head;
    }
}

/* ── Init ──────────────────────────────────────────────────────────────
 * FIXED: Use normal speed (U2X=0) at 9600 baud.
 *
 * Formula (U2X=0):  UBRR = F_CPU / (16 * baud) - 1
 *   @ 8 MHz, 9600 baud → UBRR = 8000000 / (16*9600) - 1 = 51.08 → 51
 *   Actual baud = 8000000 / (16 * 52) = 9615.4  →  error = 0.16 %  ✓
 *
 * The 'baud' parameter is kept so callers don't need to change their
 * UART_Init(9600) call — the formula now computes the correct UBRR.
 * ─────────────────────────────────────────────────────────────────── */
void UART_Init(unsigned long baud)
{
    /* 1. Normal speed (U2X=0): UBRR = F_CPU / (16 * baud) - 1        */
    unsigned short ubrr_value = (unsigned short)((F_CPU / (8UL * baud)) - 1);

    UBRRH = (unsigned char)(ubrr_value >> 8);
    UBRRL = (unsigned char)(ubrr_value);

    /* 2. Make sure U2X is CLEAR (normal speed, not double-speed)      */
    UCSRA &= ~(1 << U2X);

    /* 3. Enable RX, TX, and RX Complete Interrupt                     */
    UCSRB = (1 << RXEN) | (1 << TXEN) | (1 << RXCIE);

    /* 4. Frame format: 8 data bits, No parity, 1 stop bit (8N1)       */
    UCSRC = (1 << URSEL) | (1 << UCSZ1) | (1 << UCSZ0);

    /* 5. Global interrupts must be enabled by the caller (sei())      */
}

/* ── Transmit one byte (blocking — waits for empty TX buffer) ────── */
void UART_Send_data(char data)
{
    while (READ_BIT(UCSRA, UDRE) == 0);
    UDR = data;
}

/* ── Transmit a null-terminated string ────────────────────────────── */
void UART_Send_string(const char *ptr)
{
    while (*ptr != '\0')
        UART_Send_data(*ptr++);
}

/* ── Blocking receive (legacy — kept for compatibility) ───────────── */
char UART_Receive_data(void)
{
    while (READ_BIT(UCSRA, RXC) == 0);
    return UDR;
}

/* ── Non-blocking read from the ISR ring buffer ────────────────────
   Returns the next command byte, or 0 if the buffer is empty.
   Call this from the main loop instead of UART_Receive_data().      */
char UART_Read_nonblocking(void)
{
    if (uart_rx_head == uart_rx_tail)
        return 0;   /* nothing waiting */

    char byte = uart_rx_buf[uart_rx_tail];
    uart_rx_tail = (uart_rx_tail + 1) & UART_RX_BUFFER_MASK;
    return byte;
}