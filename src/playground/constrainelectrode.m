function [elecs]=constrainelectrode(Orignalchanlocs,side)
% the elecrode is located in 'right','left', or 'middle' or 'leftall'
% side == 'right'
% side == 'left'
% side == 'middle'
% side == 'leftall'

elecs = 1:64;%64
Y = round([Orignalchanlocs.Y],4);
X = round([Orignalchanlocs.X],4);
Z = round([Orignalchanlocs.Z],4);

if strcmp(side, 'left') == 1;
%if side == 'right'; % stimuli is applied on subject's right hand
    sel_right = Y>0;
    sel_motor = X>=0.5 ;
    sel_top   = Z>0;
    selection = sel_motor & sel_right;

elseif strcmp(side, 'right') == 1;
    %side == 'left';
    sel_left  = Y<0;
    sel_motor = X<0.5 & X>-0.5;
    sel_top   = Z>0;
    selection = sel_motor & sel_top & sel_left;
elseif strcmp(side, 'middle') == 1;
    % side == 'middle'
    sel_left  = Y<0.5 & Y>-0.5;
    sel_motor = X<0.5 & X>-0.5;
    sel_top   = Z>0;
    selection = sel_motor & sel_top & sel_left;
elseif strcmp(side,'leftall') ==1;
    sel_right = Y>=0;
    sel_motor = X<=1 & X>=-1;
    sel_top   = Z>-0.2;
    selection = sel_motor & sel_top & sel_right;
end

elecs = elecs(selection);
% plot ROI
figure;
topoplot([],Orignalchanlocs,'plotchans',elecs,'style','black','electrodes','on','emarker',{'o','k',15,1},'headrad',0.55,'plotrad',0.7);
hold on;
topoplot([],Orignalchanlocs,'plotchans',1:62,'style','black','electrodes','on','headrad',0.55,'plotrad',0.7);
end