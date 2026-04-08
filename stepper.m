clc,clear,close all
a = arduino('COM5', 'Mega2560'); % No library needed!
pins = {'D8', 'D9', 'D10', 'D11'};
moveStepper(a, pins, 512, 0.005); % Move 512 steps