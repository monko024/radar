classdef App < handle
    properties
        hView
        hModel
        hController
    end
    methods
        function obj = App(steps)
            if nargin < 1
                steps = 512; % default 90 degrees
            end
            numPos=5;
            % 1. Create instances
            obj.hController = src.Controller.controller();
            obj.hModel = src.Model.model();
            obj.hView = src.View.view();

            % 2. Link them
            obj.hController.setModel(obj.hModel);
            obj.hController.setView(obj.hView);
<<<<<<< Updated upstream
            
            % Start the N-times loop (e.g., 18 times for 360 deg if step is 20)
            obj.hController.runScan(5); 
=======

            % 3. Execute
            try
                obj.hController.runScan(steps,numPos);
                obj.hController.render();
            catch e
                fprintf('Error during run: %s\n', e.message);
                delete(findall(0, 'Type', 'serialport'));
            end
>>>>>>> Stashed changes
        end
    end
end
