/*
 * USART.h
 *
 * Created: 10/1/2025 8:19:19 PM
 *  Author: nanav
 */ 


#ifndef USART_H_
#define USART_H_

void UART_Init(unsigned long baud);
void UART_Send_data(char data);
char UART_Receive_data(void);
void UART_Send_string (const char *ptr);

#endif /* USART_H_ */