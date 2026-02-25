% =========================================================================
% QUICK START SCRIPT FOR INTERACTIVE TMA CONTROLLER
% =========================================================================

clear all; close all; clc;

fprintf('===========================================\n');
fprintf('  INTERACTIVE HYBRID TMA CONTROLLER\n');
fprintf('===========================================\n\n');

% Add current directory to path
addpath(pwd);

% Check if controller function exists
if ~exist('Interactive_TMA_Controller', 'file')
    error('Interactive_TMA_Controller.m not found in current directory!');
end

% Load previous session if exists
if exist('TMA_Controller_LastSession.mat', 'file')
    choice = questdlg('Load previous session?', ...
                     'Load Previous', ...
                     'Yes', 'No', 'Yes');
    
    if strcmp(choice, 'Yes')
        load('TMA_Controller_LastSession.mat', 'save_data');
        fprintf('Previous session loaded.\n');
    end
end

% Start the interactive controller
Interactive_TMA_Controller();

fprintf('\nController started successfully!\n');
fprintf('Instructions:\n');
fprintf('1. Use sliders to adjust phases (0-360°)\n');
fprintf('2. Try phase presets for different patterns\n');
fprintf('3. Click "Optimize" for AI time modulation\n');
fprintf('4. Save results when satisfied\n');