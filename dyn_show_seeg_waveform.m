function dyn_show_seeg_waveform(seegFile, videoFile, tsvFile, index_subj, index_session);
% This script plots 100-channel EEG data on a single figure.
% Each channel is plotted on the y-axis from top to bottom,
% with no overlap between the signals. The x-axis represents
% the time points for each channel's signal.
% Yuhan Lu, Jul 8 2024
%
% Adding sleep specific brain regions, adding interactive operation
% Yuhan Lu, Sept 2024

% a.1 load tsv
tsv = readtable(tsvFile, 'FileType', 'text', 'Delimiter', '\t','VariableNamingRule','preserve');
% a.1 load eeg
load(seegFile, 'data', 'channelFlag');
% a.1 load video
videoObj = VideoReader(videoFile);

% a.2 select ROI from tsv file
brainROI = {'Precentral', 'Postcentral', 'parietal', 'temporal', 'frontal', 'Insula', 'occipital', 'Amygdala'};
idx = false(height(tsv), 1);
for i = 1:length(brainROI)
    idx = idx | contains(tsv.("Desikan-Killiany"), brainROI{i}, 'IgnoreCase', true);
end
selectedRows = tsv(idx, [1 9]);
clear brainROI idx i

% a.3 change A'1 to Ap1
for i = 1:numel(channelFlag)
    channelFlag{i} = strrep(channelFlag{i}, '''', 'p');
end
channelFlag = channelFlag';

% a.4 reverse find channels in eeg file
for i = 1:height(selectedRows)
    idx = find(strcmp(channelFlag, selectedRows{i,1}));
    if ~isempty(idx)
        selectedChannel(i) = idx;
    else
        selectedChannel(i) = NaN;
    end
end
selectedChannel = selectedChannel';

% a.5 remove nan value
dd = isnan(selectedChannel);
selectedRows(dd,:) = []; % contain brain region
selectedChannel(dd) = []; % contain channel number
clear dd

% b.1 get channel name and time
fs = 250;
for i = 1:length(selectedChannel)
    channelName(i) = strcat(channelFlag(selectedChannel(i)), ': ', selectedRows{i,2});
end

channels = length(selectedChannel);
time = [1:size(data,1)]/fs;

% page
pageTime = 30; % 30 s per segment
currentPage = 1;

% *******
% Jieyu: we should have a memory for previous labeled trial. If this trial
% has a label, then show its result. We need a modification here
if exist(['./label_data/subj_' num2str(index_subj) '_ses_' num2str(index_session) '_seg_' num2str(currentPage) '.mat'],'file')
    load(['./label_data/subj_' num2str(index_subj) '_ses_' num2str(index_session) '_seg_' num2str(currentPage) '.mat'])

    fig_str = [...
        'Subject ' num2str(index_subj) newline...
        'Session ' num2str(index_session) newline newline...
        'Current time slot: ' newline...
        num2str(currentPage) ' / ' num2str(floor(size(data,1)/fs/30)) newline newline...
        'labeled: xxx'];
else
    fig_str = [...
        'Subject ' num2str(index_subj) newline...
        'Session ' num2str(index_session) newline newline...
        'Current time slot: ' newline...
        num2str(currentPage) ' / ' num2str(floor(size(data,1)/fs/30)) newline newline...
        'labeled: N/A'];
end
% *******

% Plot data
fig = uifigure('Name', 'sEEG Labeler', 'color', [1 1 1], 'Position', [0, 0, 1200, 1440]);
panel = uipanel(fig, 'ForegroundColor', [1 1 1], 'Position', [1000-25, 850, 150, 150]);
ax = uiaxes(fig, 'Position', [50, 150, 900, 1100]);
plot_waveforms(ax, data, time, selectedChannel, pageTime, currentPage);

annotation(panel, 'textbox', [0.5, 0.9, 0.1, 0.05], 'String', fig_str, ...
    'HorizontalAlignment', 'center', 'FontName', 'Arial', 'FitBoxToText', 'on', ...
    'FontSize', 12, 'EdgeColor', 'none');

% Set y-axis labels to show channel numbers
yticks(ax,(0:channels-1) * 1e-4);
yticklabels(ax,channelName);

% Optimize the figure display
axis(ax,'tight');

% functional bottons
prevButton = uibutton(fig, 'Text', 'Previous', 'Position', [1000, 1200, 100, 30]);
nextButton = uibutton(fig, 'Text', 'Next', 'Position', [1000, 1150, 100, 30]);
closeButton = uibutton(fig, 'Text', 'Close', 'Position', [1000, 200, 100, 30]);

incButton = uibutton(fig, 'push', 'Text', 'Increase amp', ...
    'Position', [1000, 400, 100, 30], 'ButtonPushedFcn', @(btn,event) increase_amplitude);
decButton = uibutton(fig, 'push', 'Text', 'Decrease amp', ...
    'Position', [1000, 350, 100, 30], 'ButtonPushedFcn', @(btn,event) decrease_amplitude);

% labeling botton
labels = {'N1', 'N2', 'N3', 'REM', 'Wake', 'Other'};
for i = 1:6
    uibutton(fig, 'Text', labels{i}, 'Position', [1000, 800 - (i-1)*50, 100, 30], ...
        'ButtonPushedFcn', @(btn, event) labelEEG(labels{i}));
end

% 保存标注信息
labelsData = [];

%% Tools

% Function to plot the waveforms
    function hPlot = plot_waveforms(ax, data, time, channels, pageTime, page)
        startIdx = (page - 1) * pageTime * 250 + 1;
        endIdx = startIdx + pageTime * 250 - 1;
        cla(ax);

        hold(ax, 'on');
        for i = 1:length(channels)
            % Offset each channel's signal to avoid overlap
            offset = (i - 1) * 1e-4;  % Adjust the offset as needed
            hPlot(i) = plot(ax, [startIdx:endIdx]/250, data(startIdx:endIdx, channels(i)) + offset);
        end
        xlabel(ax, 'time (s)');
        hold(ax, 'off');
    end

% Callback function to increase amplitude
    function increase_amplitude
        scale_waveforms(1.5);
    end

% Callback function to decrease amplitude
    function decrease_amplitude
        scale_waveforms(0.67);
    end

% Function to scale the waveforms
    function scale_waveforms(factor)
        for i = 1:channels
            hPlot(i).YData = (hPlot(i).YData - (i - 1) * 0.5) * factor + (i - 1) * 0.5;
        end
    end

    function nextPage()
        currentPage = currentPage + 1;
        plotEEGData(ax, EEG_data, currentPage, pageTime);
        videoFrame = read(videoObj, round(currentPage * pageTime * videoObj.FrameRate));
        imshow(videoFrame, 'Parent', videoAxes);
    end

    function prevPage()
        currentPage = max(currentPage - 1, 1);
        plotEEGData(ax, EEG_data, currentPage, pageTime);
        videoFrame = read(videoObj, round(currentPage * pageTime * videoObj.FrameRate));
        imshow(videoFrame, 'Parent', videoAxes);
    end

    function labelEEG(label)
        labelsData(end+1, :) = {currentPage, label};
        disp(['Page ' num2str(currentPage) ' labeled as ' label]);
    end

end

