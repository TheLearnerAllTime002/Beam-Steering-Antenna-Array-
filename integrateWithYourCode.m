% =========================================================================
% INTEGRATION BRIDGE: Connect Interactive Controller with Your TMA Code
% =========================================================================

function [phases_deg, switch_times, AF_dB] = integrateWithYourCode()
    % This function connects the interactive controller with your existing TMA code
    
    % Ensure global variables are accessible if needed
    global config elements results;
    
    fprintf('=== INTEGRATING WITH YOUR TMA CODE ===\n');
    
    % Check if controller is already open
    figCheck = findobj('Name', 'Interactive Hybrid TMA Controller');
    
    if isempty(figCheck)
        fprintf('Starting interactive controller...\n');
        Interactive_TMA_Controller();
    else
        fprintf('Controller is already running.\n');
        figure(figCheck); % Bring to front
    end
    
    % Wait for user instructions
    fprintf('\nINSTRUCTIONS:\n');
    fprintf('1. Adjust phases in the controller window\n');
    fprintf('2. Click "Save Results" when satisfied\n');
    fprintf('3. Press any key in Command Window to load results...\n');
    pause; 
    
    % Load saved results
    if exist('TMA_Results.mat', 'file')
        load('TMA_Results.mat', 'save_data');
        
        % Extract phases and switch times safely
        if isfield(save_data, 'config')
            phases_deg = save_data.config.phases_deg;
            switch_times = save_data.config.switch_times;
            
            % Helper for formatted printing
            fprintf('\nLoaded Configuration:\n');
            fprintf('Phases (First 5): %s ...\n', mat2str(phases_deg(1:min(5, end)), 3));
            
            if isfield(save_data.results, 'beam_pattern')
                AF_dB = save_data.results.beam_pattern.AF_dB;
            else
                AF_dB = [];
            end
        else
            error('Invalid TMA_Results.mat file format.');
        end
    else
        warning('No saved results found (TMA_Results.mat). Returning empty arrays.');
        phases_deg = [];
        switch_times = [];
        AF_dB = [];
    end
end