# Weathering-Forecasting-Station
This system monitors weather parameters such as: Air Temperature, Air-Humidity, Barometric Pressure, wind speed and Displays the average over regular intervals of an hour on an LCD display. The Display is continuous. Update of the display is done once in an hour. Weather parameters are sensed at regular intervals of 2 minutes.

The display is of the format: “Temperature – Value 0C” and so on. Other than the regular display, the user can request the display of the weather parameters to be updated at any point of time by pressing a push button key. The accuracy of the parameters monitored has to be up to two decimal points.
2
CS F241
DESCRIPTION :
Since it is not possible to obtain real time weather updates, we simulate data through sensors. Our simulation receives analog input for the system from the sensors which are connected to an 8bit parallel ADC (0808). These sensor modules generate analog voltages ~0-5V which is connected to the ADC, which in turn, generates an 8 bit value between 0 and 255.
There is an 8259 Programmable Interrupt controller device that accepts four interrupts from various sources, namely:
• The two minutes timer
• The one hour timer
• The push button and
• An EOC interrupt from the ADC.
The IVT for the 8259 is stored in the ROM at a vector address of 80h onwards (corresponding to a memory address 80h*4=00200h). There are two timer IC’s (8253) generating interrupts every 2 minutes and every one hour.
Every two minutes, an interrupt is generated and an ISR is invoked in which the ADC value is read and this digital data is stored in the RAM. It is as though an array of thirty elements is maintained for each sensor, where after the thirtieth reading of data, the next value is stored in the first position. Therefore, the past 30 readings are always maintained.
Every one hour, there is an interrupt generated that invokes an ISR that averages the values for the past hour.
For the first hour, averaging is done for only the number of values available. After averaging, the values are scaled according to the specifications of the sensors. This scaled and average value is displayed.
There is also an external button which on pressing, generates an interrupt which takes a reading and averages the past 30 readings (including the current reading i.e. the past hour). This displays value on the LCD as per the request of the external button.
3
CS F241
SCALING :
The ADC used in the design produces a value between 0d and 255d for the sensors. To scale it to the values for Pressure, Temperature and Humidity, we use a scaling function that employs the following formulae to obtain hex value:
Pressure (0-2 bar) : ADC value x 02h/FFh
Temperature (5-50°C) : ADC value x 32h/FFh
Humidity (0-99%) : ADC value x 63h/FFh
These hex values are then converted to decimal for viewing on the LCD.
ASSUMPTIONS :
1. Power supply is continuous.
2. Analog signal fed to the input of ADC.
3. The .asm file is compiled as a .bin executable file and stored permanently in the ROM.
4. The display on the LCD displays an average of the previous 30 values read, i.e. the previous hour. In case 30 values haven’t been read, the average of all available readings is taken.
5. When each time the user presses the external button, the clocks are not reset, implying that the next reading continues to take place as per the original 2 minute scheme which is set. On the button press, a new value is taken, added to data stored in memory and then, the past 30 values are averaged, scaled and displayed on the LCD monitor.
6. The button press does not clash with the 2 minute interrupt in normal usage. This is a fair assumption to make as, the probability for the same is very small in real-time usage of the weather monitoring station.
7. In case of clash during operation (highly unlikely), and non-servicing of button interrupt, a second press will ensure the servicing of the interrupts, without affecting the 2 minute interrupt-servicing.
8. For the simulations and debugging, we have connected a faster (than 2 min) output of clock to see the output changes. In actual usage, 2 minute interrupt is used.
4
