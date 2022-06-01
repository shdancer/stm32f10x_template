#include "stm32f10x.h"
#include "led.h"

int main()
{
  Led_Init();
  LightUp();
  while (1)
  {
  }
}