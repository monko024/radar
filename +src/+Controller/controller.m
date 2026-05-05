classdef controller < handle
    properties
        hView, hModel, device
        currentAngle = 0
        stepSizeDeg = 20
        stepsPerDeg = 5.5
        serialTimeoutSec = 0.5
    end

    methods
        function obj = controller()
            try
                obj.device = serialport("COM6", 9600);
                configureTerminator(obj.device, "LF");
                obj.device.Timeout = obj.serialTimeoutSec;
                pause(1);
            catch
                warning('Arduino connection failed.');
            end
        end

        function runScan(obj, nTimes)
            stepsToMove = round(obj.stepSizeDeg * obj.stepsPerDeg);
            
            for i = 1:nTimes
                % Move motor
                flush(obj.device);
                writeline(obj.device, num2str(stepsToMove));
                
                % Fast Wait
                tic;
                while obj.device.NumBytesAvailable == 0 && toc < 2
                    pause(0.01); 
                end
                readline(obj.device); 

                % Radar Capture
                try
                    pyData = py.radar_kod_pokus.capture_sweeps(int32(5));
                    M = double(pyData);
                    if ~isempty(M)
                        obj.hModel.setData(M);
                        
                        % --- FIX: Pass stepSizeDeg to the View ---
                        obj.hView.render(obj.hModel.M, obj.currentAngle, obj.stepSizeDeg);
                    end
                catch ME
                    fprintf('Radar Error: %s\n', ME.message);
                end

                % Increment angle
                obj.currentAngle = mod(obj.currentAngle + obj.stepSizeDeg, 360);
                drawnow limitrate;
            end
        end

        function setModel(obj, m), obj.hModel = m; end
        function setView(obj, v), obj.hView = v; end
    end
end