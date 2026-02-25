function Professional_TMA_Controller()
% =========================================================================
% PROFESSIONAL HYBRID TMA CONTROLLER 
% 
% ARCHITECTURE:
% 1. Core: Hybrid Particle Swarm Optimization (PSO) - 100 Iterations
% 2. Physics: Conformal Cylindrical Array Factor Synthesis
% 3. Logic: Real-time Fault Injection & Self-Healing
% 4. UI: Tabbed Professional Interface with Comprehensive Export
% =========================================================================

    % --- SYSTEM STATE INITIALIZATION ---
    clear global AppState;
    close all; clc;
    global AppState;

    % --- CONFIGURATION ---
    AppState.conf.f0 = 10e9;              
    AppState.conf.c = 3e8;                
    AppState.conf.lambda = AppState.conf.c/AppState.conf.f0;
    AppState.conf.N = 16;                 
    AppState.conf.Radius = 5 * AppState.conf.lambda;  
    AppState.conf.TargetAngle = 40;       
    
    % Geometry Generation (Cylindrical Arc)
    phi_n = linspace(-60, 60, AppState.conf.N) * (pi/180);
    AppState.geo.x = AppState.conf.Radius * cos(phi_n);
    AppState.geo.y = AppState.conf.Radius * sin(phi_n);
    AppState.geo.z = zeros(1, AppState.conf.N); 
    AppState.geo.phi = phi_n;
    
    % Variables
    AppState.status.active = true(1, AppState.conf.N); % 1=Healthy, 0=Dead
    AppState.params.phases_deg = zeros(1, AppState.conf.N);
    AppState.params.times = 0.5 * ones(1, AppState.conf.N); 
    
    % Initial Setup (Linear Scan)
    d = 0.5 * AppState.conf.lambda; 
    shift = 360 * d * sind(AppState.conf.TargetAngle) / AppState.conf.lambda;
    AppState.params.phases_deg = mod(linspace(0, (AppState.conf.N-1)*shift, AppState.conf.N), 360);
    
    % History & Reference
    AppState.ref.exists = false;
    AppState.ref.theta = [];
    AppState.ref.AF = [];
    AppState.history.cost = [];

    % --- BUILD GUI ---
    buildInterface();
    
    % --- INITIAL SOLVE ---
    updateCalculations();
    updateVisuals();

    %% ====================================================================
    %  GUI CONSTRUCTION
    %  ====================================================================
    function buildInterface()
        % Main Window
        AppState.gui.fig = figure('Name', 'TMA Professional Controller', ...
            'Position', [50, 50, 1600, 900], 'Color', [0.96 0.96 0.96], ...
            'NumberTitle', 'off', 'MenuBar', 'none');
        
        % --- 1. DARK SIDEBAR (CONTROLS) ---
        p_side = uipanel('Parent', AppState.gui.fig, 'Position', [0 0 0.22 1], ...
            'BackgroundColor', [0.15 0.15 0.17], 'BorderType', 'none');
        
        % Header
        uicontrol('Parent', p_side, 'Style', 'text', 'String', 'CONTROLS', ...
            'Units', 'normalized', 'Position', [0.05 0.96 0.9 0.03], ...
            'ForegroundColor', [0.8 0.8 0.8], 'BackgroundColor', [0.15 0.15 0.17], ...
            'FontSize', 14, 'FontWeight', 'bold');
            
        % Scrollable Elements List
        p_scroll = uipanel('Parent', p_side, 'Position', [0 0.45 1 0.5], ...
            'BackgroundColor', [0.2 0.2 0.22], 'BorderType', 'none');
        
        % Column Headers
        uicontrol('Parent', p_scroll, 'Style', 'text', 'String', 'Active  |  Phase Slider', ...
             'Units', 'normalized', 'Position', [0.05 0.96 0.9 0.03], ...
             'ForegroundColor', [1 0.7 0], 'BackgroundColor', [0.2 0.2 0.22], 'FontWeight', 'bold');

        % Dynamic Sliders
        h_row = 0.93 / 16;
        for i = 1:AppState.conf.N
            y = 0.94 - i*h_row;
            
            % Health Checkbox
            uicontrol('Parent', p_scroll, 'Style', 'checkbox', 'Value', 1, ...
                'Units', 'normalized', 'Position', [0.05 y+0.01 0.1 h_row-0.01], ...
                'BackgroundColor', [0.2 0.2 0.22], ...
                'Callback', @(s,e) cb_Status(i, s.Value));
                
            % Label
            uicontrol('Parent', p_scroll, 'Style', 'text', 'String', sprintf('E%02d',i), ...
                'Units', 'normalized', 'Position', [0.15 y 0.1 h_row], ...
                'ForegroundColor', 'w', 'BackgroundColor', [0.2 0.2 0.22], 'FontSize', 8);
                
            % Slider
            AppState.gui.sliders{i} = uicontrol('Parent', p_scroll, 'Style', 'slider', ...
                'Min', 0, 'Max', 360, 'Value', AppState.params.phases_deg(i), ...
                'Units', 'normalized', 'Position', [0.3 y+0.01 0.6 h_row-0.01], ...
                'Callback', @(s,e) cb_Phase(i, s.Value));
        end
        
        % Phase Presets Panel
        uicontrol('Parent', p_side, 'Style', 'text', 'String', 'PHASE PRESETS', ...
            'Units', 'normalized', 'Position', [0.05 0.41 0.9 0.02], ...
            'ForegroundColor', 'c', 'BackgroundColor', [0.15 0.15 0.17], 'FontWeight', 'bold');
            
        btn_h = 0.04; start_y = 0.36; gap = 0.045;
        uicontrol('Parent', p_side, 'String', 'Linear Scan (30°)', 'Units', 'normalized', ...
            'Position', [0.05 start_y 0.9 btn_h], 'Callback', @cb_PresetLinear);
        uicontrol('Parent', p_side, 'String', 'Curvature Comp.', 'Units', 'normalized', ...
            'Position', [0.05 start_y-gap 0.9 btn_h], 'Callback', @cb_PresetCurve);
        uicontrol('Parent', p_side, 'String', 'Random Phase', 'Units', 'normalized', ...
            'Position', [0.05 start_y-2*gap 0.9 btn_h], 'Callback', @cb_PresetRandom);
        uicontrol('Parent', p_side, 'String', 'Reset All', 'Units', 'normalized', ...
            'Position', [0.05 start_y-3*gap 0.9 btn_h], 'Callback', @cb_Reset);
            
        % AI & Export Panel
        uicontrol('Parent', p_side, 'Style', 'pushbutton', 'String', 'RUN AI HEALER', ...
            'Units', 'normalized', 'Position', [0.05 0.12 0.9 0.06], ...
            'BackgroundColor', [0 0.7 0.3], 'FontWeight', 'bold', 'FontSize', 11, ...
            'Callback', @cb_RunAI);
            
        uicontrol('Parent', p_side, 'Style', 'checkbox', 'String', 'Joint Opt (Time+Phase)', ...
            'Units', 'normalized', 'Position', [0.05 0.19 0.9 0.03], ...
            'BackgroundColor', [0.15 0.15 0.17], 'ForegroundColor', 'w', ...
            'Tag', 'chk_joint', 'Value', 1);
            
        uicontrol('Parent', p_side, 'String', 'Export Variables', 'Units', 'normalized', ...
            'Position', [0.05 0.06 0.42 0.04], 'Callback', @cb_ExportVars);
        uicontrol('Parent', p_side, 'String', 'Export Graph', 'Units', 'normalized', ...
            'Position', [0.53 0.06 0.42 0.04], 'Callback', @cb_ExportGraph);
            
        uicontrol('Parent', p_side, 'String', 'CLOSE', 'Units', 'normalized', ...
            'Position', [0.05 0.01 0.9 0.04], 'BackgroundColor', [0.8 0.2 0.2], ...
            'ForegroundColor', 'w', 'FontWeight', 'bold', 'Callback', @(~,~) close(AppState.gui.fig));

        % --- 2. RIGHT AREA (VISUALIZATION TABS) ---
        tabgp = uitabgroup('Parent', AppState.gui.fig, 'Position', [0.22 0 0.78 1]);
        
        % TAB 1: DASHBOARD (Standard Views)
        t1 = uitab(tabgp, 'Title', 'Main Dashboard');
        AppState.gui.ax_beam = axes('Parent', t1, 'Position', [0.08 0.55 0.60 0.38]);
        AppState.gui.ax_polar = polaraxes('Parent', t1, 'Position', [0.72 0.55 0.25 0.38]);
        AppState.gui.ax_time = axes('Parent', t1, 'Position', [0.08 0.08 0.85 0.35]);
        
        % TAB 2: PHASE ANALYSIS (Requested Curves)
        t2 = uitab(tabgp, 'Title', 'Phase & Health Analysis');
        AppState.gui.ax_ph_dist = axes('Parent', t2, 'Position', [0.1 0.70 0.8 0.22]);
        AppState.gui.ax_ph_diff = axes('Parent', t2, 'Position', [0.1 0.40 0.8 0.22]);
        AppState.gui.ax_health = axes('Parent', t2, 'Position', [0.1 0.10 0.8 0.22]);
        
        % TAB 3: 3D REALITY VIEW
        t3 = uitab(tabgp, 'Title', '3D Array View');
        AppState.gui.ax_3d = axes('Parent', t3, 'Position', [0.1 0.1 0.8 0.8]);
        
        % TAB 4: AI MONITOR
        t4 = uitab(tabgp, 'Title', 'AI Convergence');
        AppState.gui.ax_conv = axes('Parent', t4, 'Position', [0.1 0.1 0.8 0.8]);
        
        formatAxes();
    end

    function formatAxes()
        % Formatting for clean professional look
        title(AppState.gui.ax_beam, 'Beam Pattern (Comparison)'); grid(AppState.gui.ax_beam, 'on'); 
        xlabel(AppState.gui.ax_beam, 'Angle (deg)'); ylabel(AppState.gui.ax_beam, 'Gain (dB)');
        
        title(AppState.gui.ax_polar, 'Directivity Pattern');
        
        title(AppState.gui.ax_time, 'Time Modulation Weights (Duty Cycle)'); 
        xlabel(AppState.gui.ax_time, 'Element Index'); ylabel(AppState.gui.ax_time, 'Active Time');
        ylim(AppState.gui.ax_time, [0 1]);
        
        % Tab 2 Analysis Formatting
        title(AppState.gui.ax_ph_dist, 'Phase Distribution Curve'); grid(AppState.gui.ax_ph_dist, 'on');
        ylabel(AppState.gui.ax_ph_dist, 'Phase (Deg)'); xlim(AppState.gui.ax_ph_dist, [1 16]);
        
        title(AppState.gui.ax_ph_diff, 'Phase Difference (\Delta\phi) Between Elements'); grid(AppState.gui.ax_ph_diff, 'on');
        ylabel(AppState.gui.ax_ph_diff, '\Delta\phi (Deg)'); xlim(AppState.gui.ax_ph_diff, [1 15]);
        
        title(AppState.gui.ax_health, 'System Health Status (1=Active, 0=Destroyed)'); grid(AppState.gui.ax_health, 'on');
        ylabel(AppState.gui.ax_health, 'Status'); ylim(AppState.gui.ax_health, [-0.2 1.2]); xlim(AppState.gui.ax_health, [1 16]);
        
        % 3D
        title(AppState.gui.ax_3d, '3D Conformal Array Status (Red X = Destroyed)'); 
        view(AppState.gui.ax_3d, 3); axis(AppState.gui.ax_3d, 'equal'); grid(AppState.gui.ax_3d, 'on');
        
        % AI
        title(AppState.gui.ax_conv, 'Optimization Cost History'); grid(AppState.gui.ax_conv, 'on');
        xlabel(AppState.gui.ax_conv, 'Iteration'); ylabel(AppState.gui.ax_conv, 'Cost Function');
    end

    %% ====================================================================
    %  LOGIC & CALCULATIONS
    %  ====================================================================
    
    % --- CALLBACKS ---
    function cb_Status(idx, val)
        AppState.status.active(idx) = logical(val);
        AppState.ref.exists = false; % Clear old references on manual change
        updateCalculations();
        updateVisuals();
    end

    function cb_Phase(idx, val)
        AppState.params.phases_deg(idx) = val;
        AppState.ref.exists = false;
        updateCalculations();
        updateVisuals();
    end

    function cb_PresetLinear(~,~)
        d = 0.5 * AppState.conf.lambda; 
        shift = 360 * d * sind(AppState.conf.TargetAngle) / AppState.conf.lambda;
        AppState.params.phases_deg = mod(linspace(0, (AppState.conf.N-1)*shift, AppState.conf.N), 360);
        syncSliders();
    end

    function cb_PresetCurve(~,~)
        for n=1:AppState.conf.N
            path = AppState.conf.Radius * sin(AppState.geo.phi(n) - deg2rad(AppState.conf.TargetAngle));
            rad = -2*pi*path/AppState.conf.lambda;
            AppState.params.phases_deg(n) = mod(rad2deg(rad), 360);
        end
        syncSliders();
    end

    function cb_PresetRandom(~,~)
        AppState.params.phases_deg = 360*rand(1, AppState.conf.N);
        syncSliders();
    end

    function cb_Reset(~,~)
        AppState.status.active = true(1, AppState.conf.N);
        AppState.params.phases_deg = zeros(1, AppState.conf.N);
        AppState.params.times = 0.5 * ones(1, AppState.conf.N);
        AppState.ref.exists = false;
        close(AppState.gui.fig); % Brute force GUI reset to clear checkboxes easily
        Professional_TMA_Controller(); 
    end

    function syncSliders()
        for i=1:AppState.conf.N
            set(AppState.gui.sliders{i}, 'Value', mod(AppState.params.phases_deg(i), 360));
        end
        AppState.ref.exists = false;
        updateCalculations();
        updateVisuals();
    end

    % --- ALGORITHM CORE (PSO + HEALING) ---
    function cb_RunAI(~,~)
        % 1. Snapshot Broken State
        updateCalculations();
        AppState.ref.theta = AppState.calc.theta;
        AppState.ref.AF = AppState.calc.AF_dB;
        AppState.ref.exists = true;
        
        % 2. Setup
        h_chk = findobj('Tag', 'chk_joint');
        use_joint = h_chk.Value;
        faults = find(~AppState.status.active);
        
        nPart = 30; nIter = 200; % Max 100 Iterations
        if use_joint, dim = 2*AppState.conf.N; else, dim = AppState.conf.N; end
        
        pos = rand(nPart, dim); vel = zeros(nPart, dim);
        pBest=pos; pBestCost=inf(nPart,1); gBest=zeros(1,dim); gBestCost=inf;
        AppState.history.cost = [];
        
        h_wait = waitbar(0, 'Running Hybrid AI Healer...');
        
        % 3. Loop
        for it = 1:nIter
            for i = 1:nPart
                % Enforce Healing Logic: Dead Elements = 0
                if ~isempty(faults)
                    pos(i, faults) = 0; 
                    if use_joint, pos(i, AppState.conf.N + faults) = 0; end
                end
                
                % Decode
                if use_joint
                    t = pos(i, 1:AppState.conf.N);
                    p = pos(i, AppState.conf.N+1:end) * 2 * pi;
                else
                    t = pos(i, :);
                    p = deg2rad(AppState.params.phases_deg);
                end
                
                % Cost
                cost = CostFunction(t, p);
                
                if cost < pBestCost(i), pBestCost(i)=cost; pBest(i,:)=pos(i,:); end
                if pBestCost(i) < gBestCost, gBestCost=pBestCost(i); gBest=pBest(i,:); end
            end
            
            % Update
            w = 0.9 - 0.5*(it/nIter);
            vel = w*vel + 1.5*rand(nPart,dim).*(pBest-pos) + 1.5*rand(nPart,dim).*(gBest-pos);
            pos = max(min(pos+vel, 1), 0);
            
            AppState.history.cost = [AppState.history.cost; gBestCost];
            waitbar(it/nIter, h_wait, sprintf('Healing... Iter %d, Cost %.2f', it, gBestCost));
        end
        close(h_wait);
        
        % 4. Apply
        if use_joint
            AppState.params.times = gBest(1:AppState.conf.N);
            AppState.params.phases_deg = rad2deg(gBest(AppState.conf.N+1:end) * 2 * pi);
        else
            AppState.params.times = gBest;
        end
        
        syncSliders();
        msgbox('AI Optimization & Self-Healing Complete!', 'Success');
    end

    function cost = CostFunction(t, p)
        theta = -90:4:90; k = 2*pi/AppState.conf.lambda; mag = 0.8;
        w = mag .* exp(-1j * (2*pi*t + p));
        w(~AppState.status.active) = 0; % Physics constraint
        
        AF = zeros(size(theta)); ang = deg2rad(theta);
        for i=1:length(theta)
            geo = k*(AppState.geo.x .* sin(ang(i)) + AppState.geo.y .* cos(ang(i)));
            pat = cos(ang(i) - AppState.geo.phi); pat(pat<0)=0;
            AF(i) = sum(w .* exp(1j .* geo) .* pat);
        end
        AF_dB = 20*log10(abs(AF)/max(abs(AF)) + 1e-6);
        
        [~,id] = min(abs(theta - AppState.conf.TargetAngle));
        gain = AF_dB(id);
        mask = abs(theta - AppState.conf.TargetAngle) > 15;
        sll = max(AF_dB(mask));
        cost = -gain + 0.6*(sll + 25);
    end

    function updateCalculations()
        theta = -90:0.5:90; AppState.calc.theta = theta;
        k = 2*pi/AppState.conf.lambda; mag = 0.8;
        w = mag .* exp(-1j * (2*pi*AppState.params.times + deg2rad(AppState.params.phases_deg)));
        w(~AppState.status.active) = 0;
        
        AF = zeros(size(theta)); ang = deg2rad(theta);
        for i=1:length(theta)
            geo = k*(AppState.geo.x .* sin(ang(i)) + AppState.geo.y .* cos(ang(i)));
            pat = cos(ang(i) - AppState.geo.phi); pat(pat<0)=0;
            AF(i) = sum(w .* exp(1j .* geo) .* pat);
        end
        AppState.calc.AF_norm = abs(AF)/max(abs(AF));
        AppState.calc.AF_dB = 20*log10(AppState.calc.AF_norm + 1e-6);
    end

    % --- VISUALIZATION ---
    function updateVisuals()
        % 1. Beam Pattern (Comparison)
        cla(AppState.gui.ax_beam); hold(AppState.gui.ax_beam, 'on');
        if AppState.ref.exists
            plot(AppState.gui.ax_beam, AppState.ref.theta, AppState.ref.AF, 'r--', 'LineWidth', 1.5);
            plot(AppState.gui.ax_beam, AppState.calc.theta, AppState.calc.AF_dB, 'b-', 'LineWidth', 2);
            legend(AppState.gui.ax_beam, 'Broken/Target', 'Healed/Current');
        else
            plot(AppState.gui.ax_beam, AppState.calc.theta, AppState.calc.AF_dB, 'b-', 'LineWidth', 2);
            legend(AppState.gui.ax_beam, 'Current Beam');
        end
        xline(AppState.gui.ax_beam, AppState.conf.TargetAngle, 'k:', 'LineWidth', 1.5); 
        yline(AppState.gui.ax_beam, -20, 'k:'); ylim(AppState.gui.ax_beam, [-40 0]);
        
        % 2. Polar
        polarplot(AppState.gui.ax_polar, deg2rad(AppState.calc.theta), AppState.calc.AF_norm, 'LineWidth', 2);
        rlim(AppState.gui.ax_polar, [0 1]);
        
        % 3. Time Bar
        cla(AppState.gui.ax_time); hold(AppState.gui.ax_time, 'on');
        cols = repmat([0.2 0.7 0.3], AppState.conf.N, 1);
        cols(~AppState.status.active, :) = repmat([0.8 0.2 0.2], sum(~AppState.status.active), 1);
        b = bar(AppState.gui.ax_time, 1:AppState.conf.N, AppState.params.times, 'FaceColor', 'flat'); b.CData = cols;
        
        % 4. Phase Analysis Tabs
        % A. Phase Distribution
        cla(AppState.gui.ax_ph_dist);
        plot(AppState.gui.ax_ph_dist, 1:AppState.conf.N, mod(AppState.params.phases_deg,360), '-o', 'LineWidth', 2, 'Color', [0.2 0.4 0.8]);
        ylim(AppState.gui.ax_ph_dist, [0 360]); grid(AppState.gui.ax_ph_dist, 'on');
        
        % B. Phase Difference
        cla(AppState.gui.ax_ph_diff);
        p_diff = diff(mod(AppState.params.phases_deg, 360));
        p_diff = mod(p_diff + 180, 360) - 180; % Wrap to +/- 180
        bar(AppState.gui.ax_ph_diff, 1:(AppState.conf.N-1), p_diff, 'FaceColor', [0.8 0.5 0.2]);
        
        % C. Health Curve
        cla(AppState.gui.ax_health);
        stem(AppState.gui.ax_health, 1:AppState.conf.N, double(AppState.status.active), 'Filled', 'LineWidth', 2, 'Color', [0.4 0.1 0.6]);
        
        % 5. 3D View
        cla(AppState.gui.ax_3d); hold(AppState.gui.ax_3d, 'on');
        [Zc, Yc, Xc] = cylinder(AppState.conf.Radius, 50); Zc=Zc*2-1;
        surf(AppState.gui.ax_3d, Xc, Yc, Zc, 'FaceColor', [0.9 0.9 0.9], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
        
        act = find(AppState.status.active); dead = find(~AppState.status.active);
        if ~isempty(act), plot3(AppState.gui.ax_3d, AppState.geo.x(act), AppState.geo.y(act), AppState.geo.z(act), 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 10); end
        if ~isempty(dead), plot3(AppState.gui.ax_3d, AppState.geo.x(dead), AppState.geo.y(dead), AppState.geo.z(dead), 'rx', 'MarkerSize', 15, 'LineWidth', 3); end
        
        blen = AppState.conf.Radius * 1.5;
        quiver3(AppState.gui.ax_3d, 0,0,0, blen*sind(AppState.conf.TargetAngle), blen*cosd(AppState.conf.TargetAngle), 0, 'b', 'LineWidth', 4, 'MaxHeadSize', 0.5);
        
        % 6. Convergence
        cla(AppState.gui.ax_conv);
        if ~isempty(AppState.history.cost)
            plot(AppState.gui.ax_conv, AppState.history.cost, 'LineWidth', 2, 'Color', 'k');
        end
    end

    % --- EXPORT ---
    function cb_ExportVars(~,~)
        assignin('base', 'TMA_State', AppState);
        msgbox('Variables exported to workspace as "TMA_State".');
    end

    function cb_ExportGraph(~,~)
        figure('Name', 'Exported Analysis', 'Position', [50 50 1200 800], 'Color', 'w');
        
        % 1. Beam Pattern
        subplot(2,3,1); 
        plot(AppState.calc.theta, AppState.calc.AF_dB, 'LineWidth', 2); 
        grid on; title('Beam Pattern'); xlabel('Angle'); ylabel('dB');
        ylim([-50 0]); xline(AppState.conf.TargetAngle, 'r--');
        
        % 2. Polar Plot
        subplot(2,3,2); 
        polarplot(deg2rad(AppState.calc.theta), AppState.calc.AF_norm, 'LineWidth', 2); 
        title('Polar Directivity');
        
        % 3. AI Curve (Convergence)
        subplot(2,3,3);
        if ~isempty(AppState.history.cost)
            plot(AppState.history.cost, 'LineWidth', 2, 'Color', 'k');
            title(['AI Convergence (Min: ' sprintf('%.2f', min(AppState.history.cost)) ')']);
            xlabel('Iteration'); ylabel('Cost'); grid on;
        else
            text(0.5, 0.5, 'No AI Run Yet', 'HorizontalAlignment', 'center');
            title('AI Convergence'); axis off;
        end
        
        % 4. Time Weights
        subplot(2,3,4); 
        bar(AppState.params.times, 'FaceColor', [0.2 0.6 0.8]); 
        title('Time Modulation'); xlabel('Element'); ylim([0 1]);
        
        % 5. Phase Distribution
        subplot(2,3,5); 
        plot(1:AppState.conf.N, mod(AppState.params.phases_deg, 360), '-o', 'LineWidth', 1.5); 
        title('Phase Distribution'); xlabel('Element'); ylabel('Deg'); grid on;
        
        % 6. Health Status
        subplot(2,3,6);
        stem(1:AppState.conf.N, double(AppState.status.active), 'Filled', 'Color', 'r');
        title('Array Health'); ylim([-0.1 1.1]);
        
        msgbox('All Graphs (including AI Curve) exported to new figure.');
    end
end