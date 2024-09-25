function display_session_channels(fs, subject_id, mode,tsv_folder,data_folder)
    % Validate input parameters
    if ~ismember(mode, {'all', 'sleep channels only'})
        error('Invalid mode. Choose either "all" or "sleep channels only".');
    end

    % tsv and data path for subject
    tsv_path = fullfile(tsv_folder, ['sub-', num2str(subject_id), '.tsv']);
    data_path = fullfile(data_folder, ['subj_', num2str(subject_id)]);
    % Load the TSV file
    if ~exist(tsv_path, 'file')
        error('subject does not exist or subject TSV file does not exist: %s', tsv_path);
    end    
    % List session folder
    session_folders = dir(fullfile(data_path, 'subj*'));  % Assuming session folders are named like 'session1', 'session2', etc.
    session_names = {session_folders.name};  % Extract session names

    % Display session options to the user
%% filtering channels for sleep
    if strcmp(mode, 'sleep channels only')
        % Get sleep channels using the previously defined function
        load('region_struct.mat');  
        %[sleep_channels,sleep_channels_idx] = filter_channels_given_stage(tsv_path, data_folder,region_struct);
    
        % Fetching critical regions for the target stage
        stage = input('Please input the stage name (N1,N2,N3,W,REM): ', 's');
    
        if ~isfield(region_struct, stage)
            error('Invalid stage name');
        end
    
        critical_regions = region_struct.(stage);
        data_path = fullfile(data_folder, ['subj_', num2str(subject_id)]);
    
        % Read first session for the subject
        session1_path = fullfile(data_path, session_names{1});
    
        load(session1_path, 'data', 'channelFlag');  % Load data and channel flags
    
    
        % Read the TSV file
        tsv = readtable(tsv_path, 'FileType', 'text', 'Delimiter', '\t','VariableNamingRule','preserve');
    
        % Extract desired columns
        channel = tsv.Channel;
        dk = tsv.('Desikan-Killiany');
        n_chan = size(channelFlag, 1);  % Use channelFlag instead of channel for iteration
        sleep_chan = {};
        sleep_chan_idx = [];
        
        for chan = 1:n_chan
            % Find the corresponding row in the TSV file
            tsv_row = find(strcmp(channel, channelFlag{chan}));
            
            if ~isempty(tsv_row)
                if ismember(dk{tsv_row}, critical_regions)
                    sleep_chan{end+1} = channelFlag{chan};
                    sleep_chan_idx(end+1) = chan;
                end
            end
        end
    end

    %% visualization

    % List session folder
    session_folders = dir(fullfile(data_path, 'subj*'));  % Assuming session folders are named like 'session1', 'session2', etc.
    session_names = {session_folders.name};  % Extract session names

    % Display session options to the user
    disp('Available sessions:');
    for i = 1:length(session_names)
        fprintf('%d: %s\n', i, session_names{i});
    end

    % Get user input for session choice
    session_choice = input('Choose a session number: ');
    
    if session_choice < 1 || session_choice > length(session_names)
        error('Invalid session number chosen.');
    end

    % Load the data for the selected session
    session_path = fullfile(data_path, session_names{session_choice});
    
    % if ~exist(session_path, 'file')
    %     error('MAT file does not exist for the chosen session: %s', session_path);
    % end
    % 

    load(session_path, 'data', 'channelFlag');  % Load data and channel flags

   % Select channels based on mode
    if strcmp(mode, 'all')
        selected_channels = channelFlag;
        selected_channels_idx = cell(1,size(channelFlag,1));
        title_str = ['All channels for ', num2str(subject_id), ' - Session: ', num2str(session_choice)];
    elseif strcmp(mode, 'sleep channels only')
        selected_channels = sleep_chan;
        selected_channels_idx = sleep_chan_idx;
        title_str = ['Sleep-related channels for ', num2str(subject_id), ' - Session: ', num2str(session_choice)];
    else
        error('Invalid mode selected');
    end
    figure;
    hold on;
    n_chan = length(selected_channels);
    time = [1:size(data,1)]/fs;
    for i = 1:n_chan
        offset = (i-1)*1e-4;
        channel_idx = selected_channels_idx(i);
        plot(time,data(:,channel_idx)+offset)
    end
    title(title_str)
    yticks((0:n_chan-1)*1e-4);
    yticklabels(selected_channels)
    xt = 0:180:(time(end));
    xticks(xt);
    xticklabels(arrayfun(@(x) sprintf('%d min',x/60),xt,'UniformOutput',false));
    xlabel('Time (s)');
    axis tight;
    grid on;

    %dyn_show_seeg_waveform(data,fs,selected_channels)
 
end
