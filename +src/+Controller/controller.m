classdef controller < handle
    properties
        hView
        hModel
        device      % Store the serial object here
        range1 = 0
        range2 = 0.6
    end
    
    methods
        function obj = controller()
            % Setup Python
            if count(py.sys.path, pwd) == 0
                insert(py.sys.path, int32(0), pwd);
            end
            mod = py.importlib.import_module('radar_kod_pokus');
            py.importlib.reload(mod);
            
            % Initialize Serial Port ONCE
            try
                obj.device = serialport("COM6", 9600);
                configureTerminator(obj.device, "LF");
                pause(2); % Wait for Arduino to wake up
                fprintf('Serial connection established on COM6\n');
            catch
                warning('Could not connect to Arduino. Check COM6.');
            end
        end
        
        function runMotor(obj)
            if isempty(obj.device) || ~isvalid(obj.device)
                error('Serial device not connected.');
            end
            
            fprintf('Moving motor...\n');
            write(obj.device, 'M', "char");
            
            % Wait for Arduino to send "DONE"
            readline(obj.device); 
            
            % Call capture using the obj prefix
            obj.runCapture();
        end
        
        function runCapture(obj)
            cycles = 10;
            fprintf('Starting radar capture...\n');
            py.radar_kod_pokus.collect_radar_data(int32(cycles), obj.range1, obj.range2);
            
            fprintf('Capture finished. Loading data...\n');
            obj.hModel.loadData();
            
            % Automatically update the view after data is loaded
            obj.render();
        end
        
        function setModel(obj, hModel), obj.hModel = hModel; end
        function setView(obj, hView), obj.hView = hView; end
        
        function render(obj)
            obj.hView.range1 = obj.range1;
            obj.hView.range2 = obj.range2;
            obj.hView.render(obj.hModel.M);
        end

        % Cleanup when the controller is deleted
        function delete(obj)
            if ~isempty(obj.device)
                clear obj.device;
            end
        end
    end
end