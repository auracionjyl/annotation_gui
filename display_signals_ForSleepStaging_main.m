clear; clc;

data_folder = '/data/home/ruoyu/Desktop/preprocess_data';
tsv_folder = '/data/home/ruoyu/Desktop/preprocess_tsv';

fs = 250;
load('region_struct.mat')
% Fetch critical channels based on stage
subject_id = input('Please input the subject id for visualization: ');  % Define subject_id first

display_session_channels(fs, subject_id,'sleep channels only',tsv_folder,data_folder);