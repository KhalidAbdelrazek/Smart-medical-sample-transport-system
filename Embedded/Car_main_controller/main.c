/*
 * main.c
 *
 * Created: 3/1/2026
 * Author : NADER
 */
 
#include <xc.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#define F_CPU 8000000UL
#include <util/delay.h>
#include <stdio.h>   // for sprintf
 
#include "DIO.h"
#include "Timers.h"
#include "Interrupts.h"
#include "LED.h"
#include "main_movement.h"
#include "Button.h"
#include "USART.h"
 
// =========================
// Global Variables
// =========================
char last_cmd = 0;   // prevent duplicate execution
 
// =========================
// Command Handler
// =========================
void handle_command(char cmd) {
 
    // -------- Debug: show ASCII value --------
    char buffer[50];
    sprintf(buffer, "[RX] Received: '%c' (ASCII: %d)\r\n", cmd, cmd);
    UART_Send_string(buffer);
 
    // -------- Ignore newline chars --------
    if (cmd == '\r' || cmd == '\n') {
        return;
    }
 
    // -------- Prevent duplicate execution --------
    if (cmd == last_cmd) {
        UART_Send_string("[DEBUG] Duplicate command ignored\r\n");
        UART_Send_string("<ACK>\r\n");
        return;
    }
    last_cmd = cmd;
 
    // -------- Command Processing --------
    switch (cmd) {
 
        case 'F':
        case 'f':
            UART_Send_string("[DEBUG] Command: FORWARD\r\n");
            Move_Up();
            _delay_ms(10);
            UART_Send_string("<ACK>\r\n");
            break;
 
        case 'B':
        case 'b':
            UART_Send_string("[DEBUG] Command: BACKWARD\r\n");
            Move_Down();
            _delay_ms(10);
            UART_Send_string("<ACK>\r\n");
            break;
 
        case 'L':
        case 'l':
            UART_Send_string("[DEBUG] Command: LEFT\r\n");
            Move_Left();
            _delay_ms(10);
            UART_Send_string("<ACK>\r\n");
            break;
 
        case 'R':
        case 'r':
            UART_Send_string("[DEBUG] Command: RIGHT\r\n");
            Move_Right();
            _delay_ms(10);
            UART_Send_string("<ACK>\r\n");
            break;
 
        case 'S':
        case 's':
            UART_Send_string("[DEBUG] Command: STOP\r\n");
            Stop();
            _delay_ms(10);
            UART_Send_string("<ACK>\r\n");
            break;
 
        case 'T':
        case 't':
            UART_Send_string("[DEBUG] Command: TEST\r\n");
            // No motor action
            UART_Send_string("<ACK>\r\n");
            break;
 
        default:
            UART_Send_string("[ERROR] Invalid command\r\n");
            UART_Send_string("<ERR>\r\n");
            break;
    }
}
 
// =========================
// Main Function
// =========================
int main(void)
{
    // -------- Motor Pins Init (Port A) --------
    for (int i = 0; i < 8; i++) {
        DIO_Setpindir('A', i, 1);
    }
 
    // -------- Status LED --------
    LED_Init('D', 7);
    LED_On('D', 7);
    _delay_ms(1000);
    LED_Off('D', 7);
 
    // -------- UART Init --------
    UART_Init(9600);
    UART_Send_string("[DEBUG] UART Initialized @9600\r\n");
 
    char received_byte;
 
    // -------- Main Loop --------
    while (1)
    {
        received_byte = UART_Receive_data();
        handle_command(received_byte);
    }
}