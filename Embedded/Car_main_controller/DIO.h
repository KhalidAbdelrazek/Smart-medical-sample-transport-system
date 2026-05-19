/*
 * DIO.h
 *
 * Created: 7/28/2025 10:30:56 PM
 *  Author: nanav
 */ 


#ifndef DIO_H_
#define DIO_H_



void DIO_Setpindir(char port,char pin,char dir);
void DIO_Writepin(char port,char pin , char val);
void DIO_Togglepin(char port,char pin);
char DIO_Readpin(char port,char pin);
void DIO_Setportdir(char port,char dir);
void DIO_Writeport(char port,char val);
char DIO_Readport(char  port);
void DIO_Toggleport(char port);
void DIO_Connectpullup(char port,char pin,char connect);
void DIO_Writelownibble(char port,char val);
void DIO_Writehighnibble(char port,char val);


#endif /* DIO_H_ */