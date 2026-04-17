% Clean up any leftover serial connections before starting
delete(findall(0, 'Type', 'serialport'));

% Run the app - pass number of steps:
% 512  = 90 degrees
% 1024 = 180 degrees
% 2048 = 360 degrees
hApp = App(512);
