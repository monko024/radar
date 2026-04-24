classdef controller < handle
    properties
        hView
        hModel
        device
        currentAngle = 0
        stepSizeDeg = 20
        stepsPerDeg = 5.5
        serialTimeoutSec = 15  % Max seconds to wait for Arduino "DONE"
    end

    methods
        function obj = controller()
            % Python Setup
            if count(py.sys.path, pwd) == 0
                insert(py.sys.path, int32(0), pwd);
            end

            % Serial Initialization
            try
                obj.device = serialport("COM6", 9600);
                configureTerminator(obj.device, "LF");
                obj.device.Timeout = obj.serialTimeoutSec;
                pause(2); % Wait for Arduino reboot
                fprintf('Connected to Radar Motor.\n');
            catch
                warning('Arduino connection failed. Check COM6.');
            end
        end

        function runScan(obj, nTimes)
            if isempty(obj.device) || ~isvalid(obj.device)
                error('Serial device not connected.');
            end

            stepsToMove = round(obj.stepSizeDeg * obj.stepsPerDeg);

            % Initialize radar ONCE before the loop
            fprintf('Initializing radar...\n');
            py.radar_kod_pokus.radar_init(0, 2);
            fprintf('Radar initialized. Starting scan.\n');

            try
                for i = 1:nTimes
                    fprintf('Cycle %d: Moving %d steps to Angle %d...\n', i, stepsToMove, obj.currentAngle);

                    % 1. Send step count to Arduino
                    writeline(obj.device, num2str(stepsToMove));

                    % 2. Wait for Arduino "DONE" — with timeout
                    response = obj.waitForDone();
                    if isempty(response)
                        warning('Cycle %d: Timed out waiting for Arduino. Skipping cycle.', i);
                        obj.currentAngle = mod(obj.currentAngle + obj.stepSizeDeg, 360);
                        continue;
                    end

                    % 3. Brief settle pause after motor stops
                    pause(0.5);

                    % 4. Capture — with timeout guard
                    try
                        py.radar_kod_pokus.capture_sweeps(int32(10));
                        obj.hModel.loadData();
                    catch ME
                        warning('Cycle %d: Radar capture failed: %s. Skipping render.', i, ME.message);
                        obj.currentAngle = mod(obj.currentAngle + obj.stepSizeDeg, 360);
                        continue;
                    end

                    % 5. Render
                    obj.hView.render(obj.hModel.M, obj.currentAngle);

                    % 6. Advance angle
                    obj.currentAngle = mod(obj.currentAngle + obj.stepSizeDeg, 360);
                    drawnow;
                end

            catch ME
                fprintf('Error during scan: %s\n', ME.message);
            end

            % Cleanup radar once after the loop
            fprintf('Cleaning up radar...\n');
            py.radar_kod_pokus.radar_cleanup();
            fprintf('Done.\n');
        end

        function setModel(obj, m), obj.hModel = m; end
        function setView(obj, v), obj.hView = v; end
    end

    methods (Access = private)
        function response = waitForDone(obj)
            % Non-blocking poll for Arduino response, respects Timeout property
            response = '';
            deadline = tic;
            while toc(deadline) < obj.serialTimeoutSec
                if obj.device.NumBytesAvailable > 0
                    response = readline(obj.device);
                    return;
                end
                pause(0.05); % Poll every 50ms instead of blocking
            end
            % Timed out — flush buffer and return empty
            flush(obj.device);
        end
    end
end