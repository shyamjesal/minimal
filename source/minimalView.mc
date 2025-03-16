import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.Time.Gregorian as Date;

class minimalView extends WatchUi.WatchFace {

    private var background as Application.ResourceType;
    private var screenWidth;
    private var screenHeight;
    private var showSeconds = false;
    private var isLowPowerMode = false;
    private var timeFont;
    private var dateFont;
    private var WeatherFont;
    private var heart;
    private var heartOffsetLeft = 4;
    private var weatherOffsetRight = 6;

    function initialize() {
        WatchFace.initialize();
        background = Application.loadResource(Rez.Drawables.Background);
        timeFont = Application.loadResource(Rez.Fonts.TimeFont);
        dateFont = Application.loadResource(Rez.Fonts.DateFont);
        heart = Application.loadResource(Rez.Drawables.Heart);
        WeatherFont = Application.loadResource(Rez.Fonts.WeatherFont);
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        // var background = Application.loadResource(Rez.Drawables.Background);
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // Draw the UI
        drawBackground(dc);
        drawTime(dc);
        // drawSecondsText(dc, false);
        drawDate(dc);
        drawHeartRateText(dc);
        drawHeart(dc);
        drawBattery(dc);
        if(Toybox.Weather.getCurrentConditions() != null) {
            drawWeatherIcon(dc, screenWidth/2+weatherOffsetRight, screenHeight/2-30, screenWidth/2+weatherOffsetRight, screenWidth);
            drawTemperature(dc, screenWidth/2+weatherOffsetRight+25, screenHeight/2-30, true, screenWidth);
        }

        // // Draw optional animations
        // if (!isLowPowerMode) {
        //     // pumpHeart();
        //     if (System.getClockTime().sec % 15 == 0) {
        //         // blinkingEyes.blink();
        //     }
        // }
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isLowPowerMode = false;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isLowPowerMode = true;
        // heart.stop();
    }

    private function drawBackground(dc) {
        dc.drawBitmap(0, 0, background);
    }

    private function drawTime(dc) {
        var clockTime = System.getClockTime();
        var hours = clockTime.hour.format("%02d");
        var minutes = clockTime.min.format("%02d");

        var x = screenWidth / 2;
        var y = screenHeight / 2;

        // Draw hours
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            x - 3,
            y - 12,
            timeFont,
            hours,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Draw minutes
        dc.drawText(
            x + 3,
            y + 7,
            timeFont,
            minutes,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawSecondsText(dc, isPartialUpdate) {
        if (!showSeconds) {
            return;
        }

        var clockTime = System.getClockTime();
        var minutes = clockTime.min.format("%02d");
        var seconds = clockTime.sec.format("%02d");

        var minutesWidth = 48; // dc.getTextWidthInPixels(minutes, minutesFont)
        var x = screenWidth / 2 + 2 + minutesWidth + 5; // Margin right 5px
        var y = screenHeight - 100 - 20 - 2; // Visual adjustment 2px

        if (isPartialUpdate) {
            dc.setClip(
                x,
                y + 5, // Adjust for text justification 5px
                18, // dc.getTextWidthInPixels(seconds, dateFont)
                15 // Fixed height 15px
            );
            // Use the background color to force repaint the clip
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
            dc.clear();
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        }

        dc.drawText(
            x,
            y,
            dateFont,
            seconds,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

    private function drawDate(dc) {
        var now = Time.now();
        var date = Date.info(now, Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$, $2$ $3$", [date.day_of_week, date.day, date.month]);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            screenWidth / 2,
            screenHeight - 76,
            dateFont,
            dateString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawHeartRateText(dc) {
        var heartRate = 0;
        
        var info = Activity.getActivityInfo();
        if (info != null) {
            heartRate = info.currentHeartRate;
        } else {
            var latestHeartRateSample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (latestHeartRateSample != null) {
                heartRate = latestHeartRateSample.heartRate;
            }
        }

        var x = screenWidth / 2 - heartOffsetLeft - heart.getWidth() - 4; // Margin right
        var y = screenHeight / 2 + 21;

        dc.setColor(
            (heartRate != null && heartRate > 120) ? Graphics.COLOR_DK_RED : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        dc.drawText(
            x,
            y,
            dateFont,
            (heartRate == 0 || heartRate == null) ? "--" : heartRate.format("%d"),
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawBattery(dc) {
        var battery = System.getSystemStats().battery;
        var batteryInDays = System.getSystemStats().batteryInDays;

        if (batteryInDays > 2) {
            return;
        }

        var height = 12;
        var width = 18;
        var x = screenWidth / 2 - width;
        var y = screenHeight / 4 - height / 2 + 2;

        dc.setPenWidth(2);
        dc.setColor(
            battery <= 20 ? Graphics.COLOR_DK_RED : Graphics.COLOR_WHITE,
            Graphics.COLOR_TRANSPARENT
        );
        // Draw the outer rect
        dc.drawRoundedRectangle(
            x,
            y,
            width,
            height,
            2
        );
        // Draw the small + on the right
        dc.drawLine(
            x + width + 1,
            y + 3,
            x + width + 1,
            y + height - 3
        );
        // Fill the rect based on current battery
        dc.fillRectangle(
            x + 1,
            y,
            (width - 2) * battery / 100,
            height
        );

        // Draw the text
        dc.drawText(
            x + 33,
            screenHeight / 4,
            dateFont,
            batteryInDays.format("%d"),
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    private function drawHeart(dc) {
        var x = screenWidth / 2 - heartOffsetLeft - heart.getWidth();
        var y = screenHeight / 2 + 16;

        dc.drawBitmap(x, y, heart);
    }

    private function drawWeatherIcon(dc, x, y, x2, width) {
		
		var cond = Toybox.Weather.getCurrentConditions().condition;
		var sunset, sunrise;

		if (cond!=null and cond instanceof Number){
		
			var clockTime = System.getClockTime().hour;

			// gets the correct symbol (sun/moon) depending on actual sun events
			// if (check[15]) {
            var position = Toybox.Weather.getCurrentConditions().observationLocationPosition; // or Activity.Info.currentLocation if observation is null?
            var today = Toybox.Weather.getCurrentConditions().observationTime; // or new Time.Moment(Time.now().value()); ?
            if (position!=null and today!=null){
                if (Weather.getSunset(position, today)!=null) {
                    sunset = Time.Gregorian.info(Weather.getSunset(position, today), Time.FORMAT_SHORT);
                    sunset = sunset.hour; 
                } else {
                    sunset = 18; 
                }
                if (Weather.getSunrise(position, today)!=null) {
                    sunrise = Time.Gregorian.info(Weather.getSunrise(position, today), Time.FORMAT_SHORT);
                    sunrise = sunrise.hour;
                } else {
                    sunrise = 6;
                }
            } else {
                sunset = 18;
                sunrise = 6;
            }
			// } else {
			// 	sunset = 18;
			// 	sunrise = 6;
			// }			
					
			if (width<=280){
				y = y-2;
				if (width==218) {
					y = y-1;
				}
			} 

			//weather icon test
			//weather.condition = 6;

			dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			if (cond == 20) { // Cloudy
				dc.drawText(x2-1, y-1, WeatherFont, "I", Graphics.TEXT_JUSTIFY_LEFT); // Cloudy
			} else if (cond == 0 or cond == 5) { // Clear or Windy
				if (clockTime >= sunset or clockTime < sunrise) { 
							dc.drawText(x2-2, y-1, WeatherFont, "f", Graphics.TEXT_JUSTIFY_LEFT); // Clear Night	
						} else {
							dc.drawText(x2, y-2, WeatherFont, "H", Graphics.TEXT_JUSTIFY_LEFT); // Clear Day
						}
			} else if (cond == 1 or cond == 23 or cond == 40 or cond == 52) { // Partly Cloudy or Mostly Clear or fair or thin clouds
				if (clockTime >= sunset or clockTime < sunrise) { 
							dc.drawText(x2-1, y-2, WeatherFont, "g", Graphics.TEXT_JUSTIFY_LEFT); // Partly Cloudy Night
						} else {
							dc.drawText(x2, y-2, WeatherFont, "G", Graphics.TEXT_JUSTIFY_LEFT); // Partly Cloudy Day
						}
			} else if (cond == 2 or cond == 22) { // Mostly Cloudy or Partly Clear
				if (clockTime >= sunset or clockTime < sunrise) { 
							dc.drawText(x2, y, WeatherFont, "h", Graphics.TEXT_JUSTIFY_LEFT); // Mostly Cloudy Night
						} else {
							dc.drawText(x, y, WeatherFont, "B", Graphics.TEXT_JUSTIFY_LEFT); // Mostly Cloudy Day
						}
			} else if (cond == 3 or cond == 14 or cond == 15 or cond == 11 or cond == 13 or cond == 24 or cond == 25 or cond == 26 or cond == 27 or cond == 45) { // Rain or Light Rain or heavy rain or showers or unkown or chance  
				if (clockTime >= sunset or clockTime < sunrise) { 
							dc.drawText(x2, y, WeatherFont, "c", Graphics.TEXT_JUSTIFY_LEFT); // Rain Night
						} else {
							dc.drawText(x, y, WeatherFont, "D", Graphics.TEXT_JUSTIFY_LEFT); // Rain Day
						}
			} else if (cond == 4 or cond == 10 or cond == 16 or cond == 17 or cond == 34 or cond == 43 or cond == 46 or cond == 48 or cond == 51) { // Snow or Hail or light or heavy snow or ice or chance or cloudy chance or flurries or ice snow
				if (clockTime >= sunset or clockTime < sunrise) { 
							dc.drawText(x2, y, WeatherFont, "e", Graphics.TEXT_JUSTIFY_LEFT); // Snow Night
						} else {
							dc.drawText(x, y, WeatherFont, "F", Graphics.TEXT_JUSTIFY_LEFT); // Snow Day
						}
			} else if (cond == 6 or cond == 12 or cond == 28 or cond == 32 or cond == 36 or cond == 41 or cond == 42) { // Thunder or scattered or chance or tornado or squall or hurricane or tropical storm
				if (clockTime >= sunset or clockTime < sunrise) { 
							dc.drawText(x2, y, WeatherFont, "b", Graphics.TEXT_JUSTIFY_LEFT); // Thunder Night
						} else {
							dc.drawText(x, y, WeatherFont, "C", Graphics.TEXT_JUSTIFY_LEFT); // Thunder Day
						}
			} else if (cond == 7 or cond == 18 or cond == 19 or cond == 21 or cond == 44 or cond == 47 or cond == 49 or cond == 50) { // Wintry Mix (Snow and Rain) or chance or cloudy chance or freezing rain or sleet
				if (clockTime >= sunset or clockTime < sunrise) { 
							dc.drawText(x2, y, WeatherFont, "d", Graphics.TEXT_JUSTIFY_LEFT); // Snow+Rain Night
						} else {
							dc.drawText(x, y, WeatherFont, "E", Graphics.TEXT_JUSTIFY_LEFT); // Snow+Rain Day
						}
			} else if (cond == 8 or cond == 9 or cond == 29 or cond == 30 or cond == 31 or cond == 33 or cond == 35 or cond == 37 or cond == 38 or cond == 39) { // Fog or Hazy or Mist or Dust or Drizzle or Smoke or Sand or sandstorm or ash or haze
				if (clockTime >= sunset or clockTime < sunrise) { 
							dc.drawText(x2, y, WeatherFont, "a", Graphics.TEXT_JUSTIFY_LEFT); // Fog Night
				} else {
					dc.drawText(x, y, WeatherFont, "A", Graphics.TEXT_JUSTIFY_LEFT); // Fog Day
				}       		
			}
			return true;
		} else {
			return false;
		}
	}

    function drawTemperature(dc, x, y, showBoolean, width) {
		
		var TempMetric = System.getDeviceSettings().temperatureUnits;
		var temp=null, units = "", minTemp=null, maxTemp=null;
		var weather = Weather.getCurrentConditions();

		if ((weather.lowTemperature!=null) and (weather.highTemperature!=null)){ // and weather.lowTemperature instanceof Number ;  and weather.highTemperature instanceof Number
			minTemp = weather.lowTemperature;
			maxTemp = weather.highTemperature;
		}

		var offset=0;

		if(width==390){ // venu
			offset=-1;
		}
			
		if (showBoolean == false and weather!=null and (weather.feelsLikeTemperature!=null)) { //feels like ;  and weather.feelsLikeTemperature instanceof Number
			if (TempMetric == System.UNIT_METRIC or Storage.getValue(16)==true) { //Celsius
				units = "°C";
				temp = weather.feelsLikeTemperature;
			}	else {
				temp = (weather.feelsLikeTemperature * 9/5) + 32; 
				if (minTemp!=null and maxTemp!=null){
					minTemp = (minTemp* 9/5) + 32;
					maxTemp = (maxTemp* 9/5) + 32;
				}
				//temp = Lang.format("$1$", [temp.format("%d")] );
				units = "°F";
			}				
		} else if(weather!=null and (weather.temperature!=null)) {  // real temperature ;  and weather.temperature instanceof Number
				if (TempMetric == System.UNIT_METRIC or Storage.getValue(16)==true) { //Celsius
					units = "°C";
					temp = weather.temperature;
				}	else {
					temp = (weather.temperature * 9/5) + 32; 
					if (minTemp!=null and maxTemp!=null){
						minTemp = (minTemp* 9/5) + 32;
						maxTemp = (maxTemp* 9/5) + 32;
					}
					//temp = Lang.format("$1$", [temp.format("%d")] );
					units = "°F";
				}
		}
		
		if (temp != null){ // and temp instanceof Number
			dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			if ((minTemp != null) and (maxTemp != null)) { //  and minTemp instanceof Number ;  and maxTemp instanceof Number
				if (temp<=minTemp){
					if (Graphics.COLOR_WHITE == Graphics.COLOR_WHITE){ // Dark Theme
						dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT); // Light Blue 0x55AAFF
					} else { // Light Theme
						dc.setColor(0x0055AA, Graphics.COLOR_TRANSPARENT); 
					}
				} else if (temp>=maxTemp){
					if (Graphics.COLOR_WHITE == Graphics.COLOR_WHITE){ // Dark Theme
						dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT); // Light Orange
					} else { // Light Theme
						dc.setColor(0xFF5500, Graphics.COLOR_TRANSPARENT);
					}
				}				
			}

			// correcting a bug introduced by System 7 SDK
			temp=temp.format("%d");

			dc.drawText(x, y+offset, Graphics.FONT_XTINY, temp, Graphics.TEXT_JUSTIFY_LEFT); // + units
			dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
			dc.drawText(x + dc.getTextWidthInPixels(temp,Graphics.FONT_XTINY), y+offset , Graphics.FONT_XTINY, units, Graphics.TEXT_JUSTIFY_LEFT); 
		}
	}
}
