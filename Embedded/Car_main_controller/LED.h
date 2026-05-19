/*
 * LED.h
 *
 * Created: 8/2/2025 7:25:49 PM
 *  Author: nanav
 */ 


#ifndef LED_H_
#define LED_H_

void LED_Init(char port , char pin);
void LED_On(char port, char pin);
void LED_Off(char port, char pin);
void LED_Toggle(char port,char pin);
char LED_Readstatus(char port,char pin);

#endif /* LED_H_ */