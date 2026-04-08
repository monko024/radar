classdef App < handle
    properties
        hView 
        hModel 
        hController 
    end
    methods
        function obj = App()
            % 1. Create instances
            obj.hController = src.Controller.controller();
            obj.hModel = src.Model.model();
            obj.hView = src.View.view();

            % 2. Link them
            obj.hController.setModel(obj.hModel);
            obj.hController.setView(obj.hView);
            
            % 3. Execute
            obj.hController.runMotor(); 
            obj.hController.render();
        end
    end
end