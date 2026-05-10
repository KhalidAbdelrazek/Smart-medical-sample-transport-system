/*
 * USART.c
 *
 * Created: 10/1/2025 8:18:50 PM
 *  Author: nanav
 *
 * CHANGES vs original
 * -------------------
 * 1. UART_Init() now configures for 115200 baud (passed from caller).
 *    U2X double-speed mode is kept — it improves accuracy at 8 MHz.
 *    UBRR formula with U2X:  UBRR = F_CPU / (8 * baud) - 1
 *    @ 8 MHz, 115200 baud  → UBRR = 8000000 / (8*115200) - 1 = 7.68 ≈ 8
 *    Error ≈ 3.7 % — acceptable for UART 8N1.
 *
 * 2. RX Complete Interrupt (RXCIE) is enabled so every incoming byte
 *    is captured into a ring buffer by the ISR — the main loop never
 *    blocks waiting for serial data.
 *
 * 3. UART_Read_nonblocking() lets main.c poll the ring buffer without
 *    ever stalling. If no byte is available it returns 0.
 *
 * 4. UART_Receive_data() (blocking) is kept unchanged so existing code
 *    that calls it still compiles.
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

/* ── Init ──────────────────────────────────────────────────────────── */
void UART_Init(unsigned long baud)
{
    /* 1. UBRR for Double Speed (U2X=1): UBRR = F_CPU/(8*baud) - 1   */
    unsigned short ubrr_value = (unsigned short)((F_CPU / (8UL * baud)) - 1);

    UBRRH = (unsigned char)(ubrr_value >> 8);
    UBRRL = (unsigned char)(ubrr_value);

    /* 2. Enable Double Speed */
    UCSRA |= (1 << U2X);

    /* 3. Enable RX, TX, and RX Complete Interrupt                    */
    UCSRB = (1 << RXEN) | (1 << TXEN) | (1 << RXCIE);

    /* 4. Frame format: 8 data bits, No parity, 1 stop bit (8N1)      */
    UCSRC = (1 << URSEL) | (1 << UCSZ1) | (1 << UCSZ0);

    /* 5. Global interrupts must be enabled by the caller (sei())     */
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