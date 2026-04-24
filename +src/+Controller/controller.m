classdef controller < handle
    properties
        hView
        hModel
        device
        currentAngle = 0
        stepSizeDeg = 20
        stepsPerDeg = 5.5
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

            % --- Initialize radar ONCE before the loop ---
            fprintf('Initializing radar...\n');
            py.radar_kod_pokus.radar_init(0, 2);
            fprintf('Radar initialized. Starting scan.\n');

            try
                for i = 1:nTimes
                    fprintf('Cycle %d: Moving %d steps to Angle %d...\n', i, stepsToMove, obj.currentAngle);

                    % 1. Send step count to Arduino
                    writeline(obj.device, num2str(stepsToMove));

                    % 2. Wait for Arduino "DONE"
                    readline(obj.device);

                    % 3. Brief settle pause after motor stops
                    pause(0.5);

                    % 4. Capture only — no connect/disconnect overhead
                    py.radar_kod_pokus.capture_sweeps(int32(10));
                    obj.hModel.loadData();

                    % 5. Render
                    obj.hView.render(obj.hModel.M, obj.currentAngle);

                    % 6. Advance angle
                    obj.currentAngle = mod(obj.currentAngle + obj.stepSizeDeg, 360);
                    drawnow;
                end

            catch ME
                fprintf('Error during scan: %s\n', ME.message);
            end

            % --- Cleanup radar ONCE after the loop ---
            fprintf('Cleaning up radar...\n');
            py.radar_kod_pokus.radar_cleanup();
            fprintf('Done.\n');
        end

        function setModel(obj, m), obj.hModel = m; end
        function setView(obj, v), obj.hView = v; end
    end
end