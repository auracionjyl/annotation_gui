function dyn_seeg_video_syc
close all;

rootPath = '/data/home/seeg/Desktop/';

system('ls /data/home/seeg/Desktop/preprocess_data');
index_subj = input('Select which subject?: ');

system(['ls /data/home/seeg/Desktop/preprocess_data/subj_' num2str(index_subj) '/']);
index_session = input('Select which session?: ');

fprintf('entering sleep staging mode...');

% load video and seeg data
seegFile = [rootPath 'preprocess_data/subj_' num2str(index_subj) '/subj_' num2str(index_subj) '_ses_' num2str(index_session) '.mat'];
videoFile = [rootPath 'preprocess_video/sub-' num2str(index_subj) '/sub-' num2str(index_subj) '_ses-' sprintf('%02d', index_session) '.mp4'];
tsvFile = [rootPath 'preprocess_tsv/sub-' num2str(index_subj) '.tsv'];

dyn_show_seeg_waveform(seegFile, videoFile, tsvFile, index_subj, index_session);

end
