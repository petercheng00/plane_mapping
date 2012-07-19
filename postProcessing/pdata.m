function pointdata=pdata(area,cloud_file)
%Returns 1 if there is point data in the area delimited by variable area.
%Cloud_file is the path name to the corresponding *.xyz file

path(path,'Z:\indoor_modeling\code\plane_fitting');
path(path,'Z:\indoor_modeling\code\plane_fitting\misc');
path(path,'Z:\indoor_modeling\code\plane_fitting\modeling_');
path(path,'Z:\indoor_modeling\code\plane_fitting\smoothApplanix');

% Read data file and laser coordinates datafile
 [x y z line_number timestamp applanix_data] = load_modeling_data( cloud_file );    

% % % % % % % % % % % % % % % % % % % % % %      
%                     Filtering procedures                            % %
% % % % % % % % % % % % % % % % % % % % % % 
valid_idx = removeZUPT(applanix_data, timestamp);
[x,y,z, timestamp, line_number, valid_idx] = ...
          modeling_trim_data(x,y,z, timestamp, line_number, valid_idx);
disp(sprintf('Removed %d points', sum(~valid_idx)));


%Create a structure containing the point cloud data
cloud.x=x;
cloud.y=y;
cloud.z=z;

end