
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

