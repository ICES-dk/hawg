clear all
close all
clc

pathData = 'D:\git\wg_HAWG\NSAS\benchmark\results\3c_IBTSQ3\';
pathData_IBTSQ1 = 'D:\git\wg_HAWG\NSAS\benchmark\results\3b_newIBTSQ1_allAges\';

%% load data
data_IBTSQ1_old = readtable(strcat(pathData, 'data_IBTSQ1_old.csv'), 'Delimiter', ',');
data_IBTSQ1_old_array(1,:) = data_IBTSQ1_old.year;
data_IBTSQ1_old_array(2,:) = str2double(data_IBTSQ1_old.age);
data_IBTSQ1_old_array(3,:) = data_IBTSQ1_old.data;

data_IBTSQ1 = readtable(strcat(pathData, 'data_IBTSQ1.csv'), 'Delimiter', ',');
data_IBTSQ1_array(1,:) = data_IBTSQ1.year;
data_IBTSQ1_array(2,:) = str2double(data_IBTSQ1.age);
data_IBTSQ1_array(3,:) = data_IBTSQ1.data;

data_IBTSQ3 = readtable(strcat(pathData, 'data_IBTSQ3.csv'), 'Delimiter', ',');
data_IBTSQ3_array(1,:) = data_IBTSQ3.year;
data_IBTSQ3_array(2,:) = str2double(data_IBTSQ3.age);
data_IBTSQ3_array(3,:) = data_IBTSQ3.data;

data_HERAS = readtable(strcat(pathData, 'data_HERAS.csv'), 'Delimiter', ',');
data_HERAS_array(1,:) = data_HERAS.year;
data_HERAS_array(2,:) = str2double(data_HERAS.age);
data_HERAS_array(3,:) = data_HERAS.data;

% convert age 6 in age plus group
yearUnique = unique(data_HERAS_array(1,:));
for k = 1:length(yearUnique)
    data_HERAS_array(3,data_HERAS_array(2,:) == 6 & data_HERAS_array(1,:) == yearUnique(k)) = ...
        data_HERAS_array(3,data_HERAS_array(2,:) == 6 & data_HERAS_array(1,:) == yearUnique(k)) + ...
        sum(data_HERAS_array(3,data_HERAS_array(2,:) > 6 & data_HERAS_array(1,:) == yearUnique(k))); % get rid of age 1 for HERAS
end
data_HERAS_array(:,data_HERAS_array(2,:) == 1) = []; % get rid of age 1 for HERAS
data_HERAS_array(:,data_HERAS_array(2,:) > 6) = []; % get rid of age 1 for HERAS

%% plot IBTS-Q1 old and new time series
ageUnique = [1 2 3 4 5 6];

for idxAge = 1:length(ageUnique)
%     subplot(3,2,idxAge)
    x1 = data_IBTSQ1_old_array(1,data_IBTSQ1_old_array(2,:) == ageUnique(idxAge));
    y1 = data_IBTSQ1_old_array(3,data_IBTSQ1_old_array(2,:) == ageUnique(idxAge));

    x2 = data_IBTSQ1_array(1,data_IBTSQ1_array(2,:) == ageUnique(idxAge));
    y2 = data_IBTSQ1_array(3,data_IBTSQ1_array(2,:) == ageUnique(idxAge));

    yyaxis left
    h1 = plot(x1, y1, 'linewidth', 2);
    ylabel('IBTSQ1_{old}')

    yyaxis right
    h2 = plot(x2, y2, 'linewidth', 2);
    ylabel('IBTSQ1_{new}')
    title(strcat('age ',num2str(ageUnique(idxAge))))

    set(gcf, 'Units', 'centimeters');
    set(gcf, 'PaperOrientation', 'portrait ');  
    
    set(gcf, 'Units', 'centimeters');
    set(gcf, 'PaperOrientation', 'portrait ');

    % we set the position and dimension of the figure ON THE SCREEN
    %
    % NOTE: measurement units refer to the previous settings!
    afFigurePosition = [1 1 11 8]; % [pos_x pos_y width_x width_y]
    set(gcf, 'Position', afFigurePosition); % [left bottom width height]
    print('-dpng','-r300',strcat(pathData_IBTSQ1,'time series age - ', num2str(ageUnique(idxAge))))
    close(gcf)
%     fig(idxAge) = gcf;
end


%% plotting
% % age 1 for IBTS Q1 and Q3
x1 = data_IBTSQ1_array(1,data_IBTSQ1_array(2,:) == 1);
y1 = data_IBTSQ1_array(3,data_IBTSQ1_array(2,:) == 1);

x2 = data_IBTSQ3_array(1,data_IBTSQ3_array(2,:) == 1);
y2 = data_IBTSQ3_array(3,data_IBTSQ3_array(2,:) == 1);

yyaxis left
h1 = plot(x1, y1, 'linewidth', 2);
ylabel('IBTSQ1')

yyaxis right
h2 = plot(x2, y2, 'linewidth', 2);
ylabel('IBTSQ3')
title('age 1')
    
set(gcf, 'Units', 'centimeters');
set(gcf, 'PaperOrientation', 'portrait ');

% we set the position and dimension of the figure ON THE SCREEN
%
% NOTE: measurement units refer to the previous settings!
afFigurePosition = [1 1 11 8]; % [pos_x pos_y width_x width_y]
set(gcf, 'Position', afFigurePosition); % [left bottom width height]
print('-dpng','-r300',strcat(pathData,'time series age - 1'))
close(gcf)
    

% % other ages
ageUnique = [2 3 4 5 6];

for idxAge = 1:length(ageUnique)
%     subplot(3,2,idxAge)
    x1 = data_IBTSQ1_array(1,data_IBTSQ1_array(2,:) == ageUnique(idxAge));
    y1 = data_IBTSQ1_array(3,data_IBTSQ1_array(2,:) == ageUnique(idxAge));

    x2 = data_IBTSQ3_array(1,data_IBTSQ3_array(2,:) == ageUnique(idxAge));
    y2 = data_IBTSQ3_array(3,data_IBTSQ3_array(2,:) == ageUnique(idxAge));

    x3 = data_HERAS_array(1,data_HERAS_array(2,:) == ageUnique(idxAge));
    y3 = data_HERAS_array(3,data_HERAS_array(2,:) == ageUnique(idxAge));

%     plotyy(x1, y1, x2, y2)
    % legend('IBTSQ1','IBTSQ3','HERAS')

    [ax,hlines] = plotyyy(x1,y1,x2,y2,x3,y3, {'IBTSQ1','IBTSQ3','HERAS'});
    title(strcat('age ',num2str(ageUnique(idxAge))))
    
    set(hlines(1), 'linewidth', 2)
    set(hlines(2), 'linewidth', 2)
    set(hlines(3), 'linewidth', 2)    
    
    set(gcf, 'Units', 'centimeters');
    set(gcf, 'PaperOrientation', 'portrait ');

    % we set the position and dimension of the figure ON THE SCREEN
    %
    % NOTE: measurement units refer to the previous settings!
    afFigurePosition = [1 1 11 8]; % [pos_x pos_y width_x width_y]
    set(gcf, 'Position', afFigurePosition); % [left bottom width height]
    print('-dpng','-r300',strcat(pathData,'time series age - ', num2str(ageUnique(idxAge))))
    close(gcf)
%     fig(idxAge) = gcf;
end