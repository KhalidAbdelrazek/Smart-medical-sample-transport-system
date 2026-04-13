/*
 * main.c
 *
 * Created: 3/1/2026 3:44:39 PM
 *  Author: NADER
 */ 

#include <xc.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#define F_CPU 8000000UL
#include <util/delay.h>
#include "DIO.h"
#include "Timers.h"
#include "Interrupts.h"
#include "LED.h"
#include "main_movement.h"
#include "Button.h"
#include "USART.h"

void handle_command(char cmd) {
    // Debug: show raw received byte
    UART_Send_string("[RX] byte: '");
    UART_Send_data(cmd);
    UART_Send_string("'\r\n");

    switch (cmd) {
        case 'F':
        case 'f':
            UART_Send_string("[DEBUG] Command: FORWARD\r\n");
            Move_Up();
            UART_Send_string("ACK\r\n");
            break;
        case 'B':
        case 'b':
            UART_Send_string("[DEBUG] Command: BACKWARD\r\n");
            Move_Down();
            UART_Send_string("ACK\r\n");
            break;
        case 'L':
        case 'l':
            UART_Send_string("[DEBUG] Command: LEFT\r\n");
            Move_Left();
            UART_Send_string("ACK\r\n");
            break;
        case 'R':
        case 'r':
            UART_Send_string("[DEBUG] Command: RIGHT\r\n");
            Move_Right();
            UART_Send_string("ACK\r\n");
            break;
        case 'S':
        case 's':
            UART_Send_string("[DEBUG] Command: STOP\r\n");
            Stop();
            UART_Send_string("ACK\r\n");
            break;
        case 'T':
        case 't':
            UART_Send_string("[DEBUG] Command: TEST\r\n");
            // Verification command, no motor action
            UART_Send_string("ACK\r\n");
            break;
        case '\r':
        case '\n':
            // Ignore carriage return and newline
            break;
        default:
            UART_Send_string("[ERROR] Command INVALID: '");
            UART_Send_data(cmd);
            UART_Send_string("'\r\n");
            UART_Send_string("ERR\r\n");
            break;
    }
}

int main(void)
{
    // Initialize Motor Pins (Port A)
    DIO_Setpindir('A',0,1);
    DIO_Setpindir('A',1,1);
    DIO_Setpindir('A',2,1);
    DIO_Setpindir('A',3,1);
    DIO_Setpindir('A',4,1);
    DIO_Setpindir('A',5,1);
    DIO_Setpindir('A',6,1);
    DIO_Setpindir('A',7,1);
    
    // Status Indicator
    LED_Init('D',7);
    LED_On('D',7);
    _delay_ms(1000);
    LED_Off('D',7);

    // Initialize UART at 9600 baud
    UART_Init(9600);
    UART_Send_string("[DEBUG] Robotics UART Protocol Initialized (9600 Baud)\r\n");

    char received_byte;

    while(1)
    {
        // Wait for incoming data
        received_byte = UART_Receive_data();
        handle_command(received_byte);
    }
}