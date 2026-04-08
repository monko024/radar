%% Arduino Mega + 28BYJ-48: Compatibility Speed Script
% 1. Connection Logic
if ~exist('a', 'var')
    a = arduino('COM6', 'Mega2560'); 
end

% 2. Configuration - Using Cell Array {} instead of String Array []
stepPins = {'D8', 'D9', 'D10', 'D11'};
stepsPerRevolution = 2048; 

% 3. Full-Step Sequence
sequence = [1 1 0 0; 
            0 1 1 0; 
            0 0 1 1; 
            1 0 0 1];

fprintf('Starting motor. Press Ctrl+C to stop.\n');

% 4. Movement Loop
try
    for rotations = 1:5
        tic;
        for i = 1:stepsPerRevolution
            idx = mod(i-1, 4) + 1;
            
            % Writing to pins one by one to avoid the "Invalid Pin Type" error
            writeDigitalPin(a, stepPins{1}, sequence(idx, 1));
            writeDigitalPin(a, stepPins{2}, sequence(idx, 2));
            writeDigitalPin(a, stepPins{3}, sequence(idx, 3));
            writeDigitalPin(a, stepPins{4}, sequence(idx, 4));
            
            % NOTE: If this is still too slow, remove the pause.
            % If it's too fast (motor screams), keep the pause at 0.001.
            pause(0.001); 
        end
        t = toc;
        fprintf('Rotation %d done in %.2f seconds.\n', rotations, t);
    end
catch
    fprintf('\nStopped.\n');
end

% 5. Shutdown Logic - Individual calls to guarantee no errors
fprintf('Shutting down pins...\n');
writeDigitalPin(a, 'D8', 0);
writeDigitalPin(a, 'D9', 0);
writeDigitalPin(a, 'D10', 0);
writeDigitalPin(a, 'D11', 0);
fprintf('All pins LOW.\n');