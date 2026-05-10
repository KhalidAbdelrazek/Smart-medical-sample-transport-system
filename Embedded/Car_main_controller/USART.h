/*
 * USART.h
 *
 * Created: 10/1/2025 8:19:19 PM
 *  Author: nanav
 */

#ifndef USART_H_
#define USART_H_

#include <avr/io.h>

/* Circular RX buffer size — power of 2 for fast masking */
#define UART_RX_BUFFER_SIZE  16
#define UART_RX_BUFFER_MASK  (UART_RX_BUFFER_SIZE - 1)

/* Ring buffer shared between ISR and main */
extern volatile char     uart_rx_buf[UART_RX_BUFFER_SIZE];
extern volatile uint8_t  uart_rx_head;
extern volatile uint8_t  uart_rx_tail;

/* Returns 1 if at least one byte is waiting in the buffer */
#define UART_DataAvailable()  (uart_rx_head != uart_rx_tail)

void  UART_Init(unsigned long baud);
void  UART_Send_data(char data);
char  UART_Receive_data(void);         /* blocking — kept for compatibility  */
char  UART_Read_nonblocking(void);     /* non-blocking read from ring buffer  */
void  UART_Send_string(const char *ptr);

#endif /* USART_H_ */