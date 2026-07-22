classdef Energy_Tracker_Team3_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        GridLayout                matlab.ui.container.GridLayout
        LeftPanel                 matlab.ui.container.Panel
        LoadButton_2              matlab.ui.control.Button
        NetEditField              matlab.ui.control.NumericEditField
        NetLabel                  matlab.ui.control.Label
        ProducedEditField         matlab.ui.control.NumericEditField
        ConsumedEditField         matlab.ui.control.NumericEditField
        ConsumedEditFieldLabel    matlab.ui.control.Label
        MachineDropdown           matlab.ui.control.DropDown
        MachineDropDownLabel      matlab.ui.control.Label
        ImportGymDataFileLabel    matlab.ui.control.Label
        LoadButton                matlab.ui.control.Button
        EcoGymEnergyTrackerLabel  matlab.ui.control.Label
        RightPanel                matlab.ui.container.Panel
        TabGroup                  matlab.ui.container.TabGroup
        DashboardTab              matlab.ui.container.Tab
        StatusLamp                matlab.ui.control.Lamp
        StatusLabel               matlab.ui.control.Label
        PowerGauge                matlab.ui.control.Gauge
        PowerGaugeLabel           matlab.ui.control.Label
        UIAxes                    matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    properties (Access = private)
        PowerData    % Stores the numeric power readings
        EquipmentIDs % Stores the formatted machine IDs
        UniqueIDs    % To hold the unique machine list
        ResultsTable % To hold the final energy matrix table
    end
    
    methods (Access = private)
        
        function updateMachineUI(app)
    % 1. Get the currently selected machine ID from the dropdown
    selectedMachine = app.MachineDropdown.Value;
    
    % 2. Extract and display energy calculations from your results table
    rowIdx = strcmp(app.ResultsTable.MachineName, selectedMachine);
    
    app.ConsumedEditField.Value = app.ResultsTable.ConsumedEnergy_kWh(rowIdx);
    app.ProducedEditField.Visible = "off";
    app.NetEditField.Value = app.ResultsTable.NetEnergy_kWh(rowIdx);
    
    % 3. Plot the raw power profile for the selected machine on UIAxes
    % Filter the main power data array matching this machine's ID
    machineReadings = app.PowerData(strcmp(app.EquipmentIDs, selectedMachine));
    
    % Generate a simple timeline index array (X-axis) for the data points
    timeAxis = 1:numel(machineReadings); 
    
    % Notice 'app.UIAxes' tells MATLAB exactly which app screen element to draw on
    plot(app.UIAxes, timeAxis, machineReadings, 'LineWidth', 1.5, 'Color', [0 0.447 0.741]);
    title(app.UIAxes, ['Power Consumption Profile: ' selectedMachine]);
    xlabel(app.UIAxes, 'Data Sample Index');
    ylabel(app.UIAxes, 'Power (Watts)');
    grid(app.UIAxes, 'on');
end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % 1. Load the data from the .mat file
loadedData = load('equipment_power_consumption.mat');

% Ensure the 'power_consumption' variable exists in the .mat file
if ~isfield(loadedData, 'power_consumption')
    error('The .mat file must contain a variable named ''power_consumption''.');
end

powerReadingsStruct = loadedData.power_consumption; % This is the structure containing all fields

% --- Extract actual data and group by equipment_id ---
% Based on fieldnames, assuming 'power_W' contains numeric data and 'equipment_id' identifies machines.
if isfield(powerReadingsStruct, 'power_W') && isfield(powerReadingsStruct, 'equipment_id')
    powerData = powerReadingsStruct.power_W;
    equipmentIDs = powerReadingsStruct.equipment_id;

    % Ensure powerData and equipmentIDs have compatible sizes
    if numel(powerData) ~= numel(equipmentIDs)
        error('The ''power_W'' and ''equipment_id'' fields must have the same number of elements.');
    end

    % Convert equipmentIDs to a cell array of strings if they are numeric or char arrays
    if isnumeric(equipmentIDs)
        equipmentIDs = arrayfun(@num2str, equipmentIDs, 'UniformOutput', false);
    elseif ischar(equipmentIDs) && isrow(equipmentIDs) % For a single string equipment_id, treat as one machine
        equipmentIDs = {equipmentIDs};
    elseif ischar(equipmentIDs) % If it's a char array (like multiple rows of chars), convert to cell array
        equipmentIDs = cellstr(equipmentIDs);
    end

    % Get unique equipment IDs and their corresponding indices
    [uniqueIDs, ~, idx] = unique(equipmentIDs, 'stable'); % 'stable' preserves original order

    % --- Assumptions ---
    % 1. Time duration per power reading:
    %    Energy (kWh) = Power (kW) * Time (hours).
    %    This assumes each reading represents average power over the specified timeStep_hours.
    %    ADJUST THIS VALUE if your data has a different sampling interval.
    timeStep_hours = 30 / 3600; % Automatically set based on previous conversation (30 seconds)

    % Initialize results for individual machines
    netEnergy = zeros(1, numel(uniqueIDs));
    consumedEnergy = zeros(1, numel(uniqueIDs));
    producedEnergy = zeros(1, numel(uniqueIDs));
    machineNames = cell(1, numel(uniqueIDs));

    fprintf('\n--- Energy Consumption/Production for Each Machine ---\n');

    for i = 1:numel(uniqueIDs)
        currentID = uniqueIDs{i};
        % Find all power readings for the current equipment ID
        machinePowerReadings = powerData(idx == i);

        % Separate positive (consumption) and negative (production) power readings
        positivePower = machinePowerReadings(machinePowerReadings > 0);
        negativePower = machinePowerReadings(machinePowerReadings < 0);

        % Calculate total consumed energy for this machine
        consumedEnergy(i) = sum(positivePower) * timeStep_hours / 1000; % Total kWh

        % Calculate total produced energy for this machine (take absolute value of sum of negative power)
        producedEnergy(i) = abs(sum(negativePower)) * timeStep_hours / 1000; % Total kWh

        % Calculate net energy (consumption - production)
        netEnergy(i) = consumedEnergy(i) - producedEnergy(i);

        machineNames{i} = currentID; % Use the equipment ID as the machine name
        fprintf('Machine Name: %s, Net Energy: %.2f kWh (Consumed: %.2f kWh, Produced: %.2f kWh)\n', ...
                machineNames{i}, netEnergy(i), consumedEnergy(i), producedEnergy(i));
    end

    fprintf('\n--- Power Reading Range (Min/Max Power_W) ---\n');
    for i = 1:numel(uniqueIDs)
        currentID = uniqueIDs{i};
        machinePowerReadings = powerData(idx == i);
        minPower = min(machinePowerReadings);
        maxPower = max(machinePowerReadings);
        fprintf('Machine Name: %s, Min Power_W: %.2f, Max Power_W: %.2f\n', currentID, minPower, maxPower);
    end

    % You can also create a new table for easier viewing
    if ~isempty(netEnergy) && ~isempty(machineNames)
        resultsTable = table(machineNames(:), netEnergy(:), consumedEnergy(:), producedEnergy(:), ...
                             'VariableNames', {'MachineName', 'NetEnergy_kWh', 'ConsumedEnergy_kWh', 'ProducedEnergy_kWh'});
        disp(resultsTable);
    end

else
    error('The ''power_consumption'' structure must contain both ''power_W'' and ''equipment_id'' fields for individual machine readings.');
end

        

% --- Save data to your global App Properties ---
app.PowerData = powerData;
app.EquipmentIDs = equipmentIDs;
app.UniqueIDs = uniqueIDs;
app.ResultsTable = resultsTable;

if ~isempty(netEnergy) && ~isempty(machineNames)
    app.ResultsTable = table(machineNames(:), netEnergy(:), consumedEnergy(:), producedEnergy(:), ...
        'VariableNames', {'MachineName', 'NetEnergy_kWh', 'ConsumedEnergy_kWh', 'ProducedEnergy_kWh'});
end

% --- Link to the UI ---
% Populates the dropdown selection list with your gym machine IDs
app.MachineDropdown.Items = app.UniqueIDs;
app.MachineDropdown.Value = app.UniqueIDs{1};

% Run the plotting/calculation function for the first machine by default
app.updateMachineUI();

        end

        % Value changed function: MachineDropdown
        function MachineDropdownValueChanged(app, event)
            value = app.MachineDropdown.Value;
            disp('>>> DROPDOWN CALLBACK IS ACTIVELY RUNNING NOW! <<<');

            % 1. Get the current selection from the dropdown
            selectedMachine = app.MachineDropdown.Value;

            % 2. Find the row in the results table for this machine
            rowIdx = strcmp(app.ResultsTable.MachineName, selectedMachine);

            % 3. Update the three numeric fields on your screen
            app.ConsumedEditField.Value = app.ResultsTable.ConsumedEnergy_kWh(rowIdx);
            app.ProducedEditField.Visible = "off";
            app.NetEditField.Value = app.ResultsTable.NetEnergy_kWh(rowIdx);

            % 4. Filter the raw power data for this specific machine
            machineReadings = app.PowerData(strcmp(app.EquipmentIDs, selectedMachine));
            timeAxis = (0:numel(machineReadings)-1) * (30 / 3600); 

            % 5. Plot to the Axes component on your screen
            plot(app.UIAxes, timeAxis, machineReadings, 'LineWidth', 1.5, 'Color', [0 0.45 0.74]);

            % 6. Add visual labels
            title(app.UIAxes, ['Power Profile: ' selectedMachine]);
            xlabel(app.UIAxes, 'Elapsed Time (Hours)');
            ylabel(app.UIAxes, 'Power (Watts)');
            grid(app.UIAxes, 'on');

            % --- UPDATE POWER GAUGE ---
            % 1. Calculate the maximum power spike for the selected machine
            maxPower = max(machineReadings);

            % 2. Push that value to your Gauge component
            app.PowerGauge.Value = maxPower;

            % --- UPDATE STATUS LAMP ---
    % 1. Check if the machine's maximum power exceeds a threshold (e.g., 1500W)
    maxPower = max(machineReadings);
    
    if maxPower > 1500
        app.StatusLamp.Color = [1 0 0];    % Bright Red [R G B]
    elseif maxPower > 800
        app.StatusLamp.Color = [1 0.6 0];  % Orange/Yellow for medium load
    else
        app.StatusLamp.Color = [0 1 0];    % Bright Green for low load
    end

    
            
        end

        % Button pushed function: LoadButton_2
        function LoadButton_Pushed(app, event)
            % Button pushed function: LoadButton
            function LoadButtonPushed(app, event)
                % 1. Open the native computer file browser to pick any .mat file
                [filename, pathname] = uigetfile('*.mat', 'Select Your Gym Data File');

                % 2. If the user clicks 'Cancel', stop running
                if isequal(filename, 0) || isequal(pathname, 0)
                    return; 
                end

                % 3. Assemble the path and read the file the user imported
                fullFilePath = fullfile(pathname, filename);
                importedData = load(fullFilePath);

                % 4. Verify file structure and extract variables
                if ~isfield(importedData, 'power_consumption')
                    uialert(app.UIFigure, 'The selected file does not contain a "power_consumption" structure.', 'Import Error');
                    return;
                end

                powerReadingsStruct = importedData.power_consumption; 

                if isfield(powerReadingsStruct, 'power_W') && isfield(powerReadingsStruct, 'equipment_id')
                    powerData = powerReadingsStruct.power_W;
                    equipmentIDs = powerReadingsStruct.equipment_id;

                    % 5. Format and process data (Your teammate's logic)
                    if numel(powerData) ~= numel(equipmentIDs)
                        uialert(app.UIFigure, 'The power_W and equipment_id fields must have the same size.', 'Data Size Mismatch');
                        return;
                    end

                    if isnumeric(equipmentIDs)
                        equipmentIDs = arrayfun(@num2str, equipmentIDs, 'UniformOutput', false);
                    elseif ischar(equipmentIDs) && isrow(equipmentIDs)
                        equipmentIDs = {equipmentIDs};
                    elseif ischar(equipmentIDs)
                        equipmentIDs = cellstr(equipmentIDs);
                    end

                    [uniqueIDs, ~, idx] = unique(equipmentIDs, 'stable');
                    timeStep_hours = 30 / 3600; 

                    netEnergy = zeros(1, numel(uniqueIDs));
                    consumedEnergy = zeros(1, numel(uniqueIDs));
                    producedEnergy = zeros(1, numel(uniqueIDs));
                    machineNames = cell(1, numel(uniqueIDs));

                    for i = 1:numel(uniqueIDs)
                        machinePowerReadings = powerData(idx == i);
                        positivePower = machinePowerReadings(machinePowerReadings > 0);
                        negativePower = machinePowerReadings(machinePowerReadings < 0);

                        consumedEnergy(i) = sum(positivePower) * timeStep_hours / 1000;
                        producedEnergy(i) = abs(sum(negativePower)) * timeStep_hours / 1000;
                        netEnergy(i) = consumedEnergy(i) - producedEnergy(i);
                        machineNames{i} = uniqueIDs{i};
                    end

                    resultsTable = table(machineNames(:), netEnergy(:), consumedEnergy(:), producedEnergy(:), ...
                        'VariableNames', {'MachineName', 'NetEnergy_kWh', 'ConsumedEnergy_kWh', 'ProducedEnergy_kWh'});

                    % 6. Save data to permanent app properties
                    app.PowerData = powerData;
                    app.EquipmentIDs = equipmentIDs;
                    app.UniqueIDs = uniqueIDs;
                    app.ResultsTable = resultsTable;

                    % 7. Update UI components
                    app.MachineDropdown.Items = app.UniqueIDs;
                    app.MachineDropdown.Value = app.UniqueIDs{1};

                    % 8. Trigger the dropdown callback function to draw the graph for the first machine
                    MachineDropdownValueChanged(app, []);
                end
            end
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {563, 563};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {260, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 741 563];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {260, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create EcoGymEnergyTrackerLabel
            app.EcoGymEnergyTrackerLabel = uilabel(app.LeftPanel);
            app.EcoGymEnergyTrackerLabel.FontSize = 18;
            app.EcoGymEnergyTrackerLabel.FontWeight = 'bold';
            app.EcoGymEnergyTrackerLabel.Position = [21 535 220 23];
            app.EcoGymEnergyTrackerLabel.Text = 'Eco-Gym Energy Tracker';

            % Create LoadButton
            app.LoadButton = uibutton(app.LeftPanel, 'push');
            app.LoadButton.Position = [67 116 100 22];
            app.LoadButton.Text = 'Press Here';

            % Create ImportGymDataFileLabel
            app.ImportGymDataFileLabel = uilabel(app.LeftPanel);
            app.ImportGymDataFileLabel.Position = [61 152 119 22];
            app.ImportGymDataFileLabel.Text = 'Import Gym Data File';

            % Create MachineDropDownLabel
            app.MachineDropDownLabel = uilabel(app.LeftPanel);
            app.MachineDropDownLabel.HorizontalAlignment = 'right';
            app.MachineDropDownLabel.Position = [26 469 80 22];
            app.MachineDropDownLabel.Text = 'Machine Type';

            % Create MachineDropdown
            app.MachineDropdown = uidropdown(app.LeftPanel);
            app.MachineDropdown.ValueChangedFcn = createCallbackFcn(app, @MachineDropdownValueChanged, true);
            app.MachineDropdown.Position = [120 469 100 22];

            % Create ConsumedEditFieldLabel
            app.ConsumedEditFieldLabel = uilabel(app.LeftPanel);
            app.ConsumedEditFieldLabel.HorizontalAlignment = 'right';
            app.ConsumedEditFieldLabel.Position = [41 371 76 22];
            app.ConsumedEditFieldLabel.Text = 'Consumption';

            % Create ConsumedEditField
            app.ConsumedEditField = uieditfield(app.LeftPanel, 'numeric');
            app.ConsumedEditField.Position = [132 371 100 22];

            % Create ProducedEditField
            app.ProducedEditField = uieditfield(app.LeftPanel, 'numeric');
            app.ProducedEditField.Visible = 'off';
            app.ProducedEditField.Position = [74 60 100 22];

            % Create NetLabel
            app.NetLabel = uilabel(app.LeftPanel);
            app.NetLabel.HorizontalAlignment = 'right';
            app.NetLabel.Position = [92 294 25 22];
            app.NetLabel.Text = 'Net';

            % Create NetEditField
            app.NetEditField = uieditfield(app.LeftPanel, 'numeric');
            app.NetEditField.Position = [132 294 100 22];

            % Create LoadButton_2
            app.LoadButton_2 = uibutton(app.LeftPanel, 'push');
            app.LoadButton_2.ButtonPushedFcn = createCallbackFcn(app, @LoadButton_Pushed, true);
            app.LoadButton_2.Position = [67 115 100 22];
            app.LoadButton_2.Text = 'Press Here';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create TabGroup
            app.TabGroup = uitabgroup(app.RightPanel);
            app.TabGroup.Position = [6 7 462 550];

            % Create DashboardTab
            app.DashboardTab = uitab(app.TabGroup);
            app.DashboardTab.Title = 'Dashboard';

            % Create UIAxes
            app.UIAxes = uiaxes(app.DashboardTab);
            title(app.UIAxes, 'Title')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [26 18 391 309];

            % Create PowerGaugeLabel
            app.PowerGaugeLabel = uilabel(app.DashboardTab);
            app.PowerGaugeLabel.HorizontalAlignment = 'center';
            app.PowerGaugeLabel.Position = [170 354 111 22];
            app.PowerGaugeLabel.Text = 'Peak Power (Watts)';

            % Create PowerGauge
            app.PowerGauge = uigauge(app.DashboardTab, 'circular');
            app.PowerGauge.Limits = [0 2000];
            app.PowerGauge.Position = [163 391 120 120];

            % Create StatusLabel
            app.StatusLabel = uilabel(app.DashboardTab);
            app.StatusLabel.HorizontalAlignment = 'right';
            app.StatusLabel.Position = [325 479 63 33];
            app.StatusLabel.Text = 'Status:';

            % Create StatusLamp
            app.StatusLamp = uilamp(app.DashboardTab);
            app.StatusLamp.Position = [394 481 29 29];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Energy_Tracker_Team3_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end