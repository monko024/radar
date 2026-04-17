classdef App < handle
    properties
        hView 
        hModel 
        hController 
    end
    methods
        function obj = App()
            obj.hModel = src.Model.model();
            obj.hView = src.View.view();
            obj.hController = src.Controller.controller();

            obj.hController.setModel(obj.hModel);
            obj.hController.setView(obj.hView);
            
            % Start the N-times loop (e.g., 18 times for 360 deg if step is 20)
            obj.hController.runScan(5); 
        end
    end
end