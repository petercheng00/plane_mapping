function checkOcclusion(planes, plane_index)
  target_plane = planes(plane_index);
  images = target_plane.images;
  for i = 1:size(images,2)
      disp(['Checking occlusion for image ', num2str(i)]);
      curr_box = images(i).mytile_on_plane.orig_box;
      gridStepY = ceil((curr_box.row_max - curr_box.row_min)/4);
      gridStepX = ceil((curr_box.col_max - curr_box.col_min)/4);
      maxSubDivs = 2;
      numSectionsY = ceil((curr_box.row_max - curr_box.row_min + 1)/gridStepY);
      numSectionsX = ceil((curr_box.col_max - curr_box.col_min + 1)/gridStepX);
      for j = 1:numSectionsY
          for k = 1:numSectionsX
              row_min = curr_box.row_min + (j-1) * gridStepY;
              row_max = min(curr_box.row_min + (j * gridStepY), curr_box.row_max);
              col_min = curr_box.col_min + (k-1) * gridStepX;
              col_max = min(curr_box.col_min + (k * gridStepX), curr_box.col_max);
              subdivideForOcclusion(planes, plane_index, i, 0, maxSubDivs, ...
                  row_min, row_max, col_min, col_max);
          end
      end
      if (sum(sum(target_plane.images(i).mytile_on_plane.orig_valid)) > 0) && (numel(target_plane.images(i).mytile_on_plane.orig_valid) > 0)
          target_plane.images(i).mytile_on_plane = target_plane.images(i).mytile_on_plane.crop();
          target_plane.images(i).mytile_on_plane = target_plane.images(i).mytile_on_plane.set_border_mask(target_plane.blendpx);
      else
          target_plane.images(i).useful = false;
      end
  end
end

function subdivideForOcclusion(planes, plane_index, imgnum, depth, maxDepth, ...
                        row_min, row_max, col_min, col_max)
  target_plane = planes(plane_index);
  %if depth == maxDepth
  %    occludeRectangle(target_plane, imgnum, row_min, row_max, col_min, col_max);
  %    return
  %end    
  box = target_plane.images(imgnum).mytile_on_plane.orig_box;
  data = target_plane.images(imgnum).mytile_on_plane.orig_data;
  data_in_section = data(row_min-box.row_min+1:row_max-box.row_min+1,...
          col_min-box.col_min+1:col_max-box.col_min+1,:);
  if sum(sum(sum(data_in_section))) == 0
      return;
  end
  
  camera_pt_world = target_plane.images(imgnum).t;
  LL_pt_plane = [row_max; col_min];
  LL_pt_world = target_plane.get_world_pts(LL_pt_plane);
  UL_pt_plane = [row_min; col_min];
  UL_pt_world = target_plane.get_world_pts(UL_pt_plane);
  UR_pt_plane = [row_min; col_max];              
  UR_pt_world = target_plane.get_world_pts(UR_pt_plane);
  LR_pt_plane = [row_max; col_max];              
  LR_pt_world = target_plane.get_world_pts(LR_pt_plane);
  
  % 5 test points = 4 corners + center point
  % not using center, can't think of a good use
  % if all are bad, then occlude the entire section.
  % if none are bad, do nothing
  % else subdivide and do a recursive call
  LL_result = occludedOrOffPlane(planes, plane_index, LL_pt_world, camera_pt_world);
  UL_result = occludedOrOffPlane(planes, plane_index, UL_pt_world, camera_pt_world);
  UR_result = occludedOrOffPlane(planes, plane_index, UR_pt_world, camera_pt_world);
  LR_result = occludedOrOffPlane(planes, plane_index, LR_pt_world, camera_pt_world);
  if LL_result && UL_result && UR_result && LR_result
      %plot(planes(plane_index).vertices(1,:),planes(plane_index).vertices(2,:))
      %hold on
      %verts = [LL_pt_world,LR_pt_world,UR_pt_world,UL_pt_world];
      %scatter(verts(1,:),verts(2,:))
      %keyboard
      occludeRectangle(target_plane, imgnum, row_min, row_max, col_min, col_max);
      return
  end
  if ~(LL_result || UL_result || UR_result || LR_result)
      return
  end
  if 1
      if (depth == maxDepth)
          % this does color-based occlusion, but not very well.
          if 0
              [rows columns, channels] = size(data_in_section);
              rChannel = data_in_section(:,:,1);
              gChannel = data_in_section(:,:,2);
              bChannel = data_in_section(:,:,3);
              LL_data = squeeze(data_in_section(rows-1,2,:));
              UL_data = squeeze(data_in_section(2,2,:));
              UR_data = squeeze(data_in_section(2,columns-1,:));
              LR_data = squeeze(data_in_section(rows-1,columns-1,:));
              val = [0;0;0];
              numVals = 0;
              if LL_result && sum(LL_data)>0
                  val  = val + LL_data;
                  numVals = numVals+1;
              end
              if UL_result && sum(UL_data)>0
                  val  = val + UL_data;
                  numVals = numVals+1;
              end
              if UR_result && sum(UR_data)>0
                  val  = val + UR_data;
                  numVals = numVals+1;
              end
              if LR_result && sum(LR_data)>0
                  val  = val + LR_data;
                  numVals = numVals+1;
              end
              if numVals == 0
                  return
              end
              avgVal = val / numVals;

              rMean = avgVal(1);
              gMean = avgVal(2);
              bMean = avgVal(3);
              rStandard = rMean * ones(rows, columns);
              gStandard = gMean * ones(rows, columns);
              bStandard = bMean * ones(rows, columns);    
              deltar = rChannel - rStandard;
              deltag = gChannel - gStandard;
              deltab = bChannel - bStandard;      
              deltaE = sqrt(deltar .^ 2 + deltag .^ 2 + deltab .^ 2);   
              binaryImage = deltaE <= 30;
              binaryImage = repmat(binaryImage, [1,1,3]);
              data_in_section(binaryImage) = 0;
              %target_plane.images(imgnum).mytile_on_plane.orig_data(row_min-box.row_min+1:row_max-box.row_min+1, ... 
          %col_min-box.col_min+1:col_max-box.col_min+1,:) = data_in_section;
              fillRectangleWithData(target_plane, imgnum, row_min, row_max, col_min, col_max, data_in_section);
          end
          if 1
            %if sum([LL_result, UL_result, UR_result, LR_result]) == 1
            %    keyboard
            %    if LL_result
            %        occludeTriangle('LL', target_plane, imgnum, row_min, row_max, col_min, col_max);
            %    end
            %    if UL_result
            %        occludeTriangle('UL', target_plane, imgnum, row_min, row_max, col_min, col_max);
            %    end
            %%    if UR_result
            %        occludeTriangle('UR', target_plane, imgnum, row_min, row_max, col_min, col_max);
            %    end
            %    if LR_result
            %        occludeTriangle('LR', target_plane, imgnum, row_min, row_max, col_min, col_max);
            %    end
            %    keyboard
            if sum([LL_result, UL_result, UR_result, LR_result]) == 2
                %if LL_result && UL_result
                %    occludeRectangle(target_plane, imgnum, row_min, row_max, col_min, round((col_min+col_max)/2));
                %end
                %if UL_result && UR_result
                %    occludeRectangle(target_plane, imgnum, row_min, round((row_min+row_max)/2), col_min, col_max);
                %end
                %if UR_result && LR_result
                %    occludeRectangle(target_plane, imgnum, round((row_min+row_max)/2), row_max, round((col_min+col_max)/2), col_max);
                %end
                %if LR_result && LL_result
                %    occludeRectangle(target_plane, imgnum, round((row_min+row_max)/2), row_max, col_min, col_max);
                %end
            elseif sum([LL_result, UL_result, UR_result, LR_result]) == 3
                if ~LL_result
                    occludeTriangle('UR', target_plane, imgnum, row_min, row_max, col_min, col_max);
                end
                if ~UL_result
                    occludeTriangle('LR', target_plane, imgnum, row_min, row_max, col_min, col_max);
                end
                if ~UR_result
                    occludeTriangle('LL', target_plane, imgnum, row_min, row_max, col_min, col_max);
                end
                if ~LR_result
                    occludeTriangle('UL', target_plane, imgnum, row_min, row_max, col_min, col_max);
                end
            end
          return
          end
      end
  end
  subdivideForOcclusion(planes, plane_index, imgnum, depth+1, maxDepth, ...
      row_min, round((row_max+row_min)/2), col_min, round((col_max+col_min)/2));
  subdivideForOcclusion(planes, plane_index, imgnum, depth+1, maxDepth, ...
      row_min, round((row_max+row_min)/2), round((col_max+col_min)/2), col_max);
  subdivideForOcclusion(planes, plane_index, imgnum, depth+1, maxDepth, ...
      round((row_max+row_min)/2), row_max, col_min, round((col_max+col_min)/2));
  subdivideForOcclusion(planes, plane_index, imgnum, depth+1, maxDepth, ...
      round((row_max+row_min)/2), row_max, round((col_max+col_min)/2), col_max);

end

function invalid = occludedOrOffPlane(planes, plane_index, plane_pt, source_pt)
  [center_2d, vertices_2d] = project_2d(planes(plane_index), plane_pt);
  
  onPlane = polygonCheck(center_2d, vertices_2d);
  invalid = (~onPlane) || (isoccluded(plane_pt, source_pt, planes, plane_index));
end

function occludeRectangle(target_plane, imgnum, row_min, row_max, col_min, col_max)
  curr_box = target_plane.images(imgnum).mytile_on_plane.orig_box;
  target_plane.images(imgnum).mytile_on_plane.orig_valid(row_min-curr_box.row_min+1:row_max-curr_box.row_min+1, ... 
      col_min-curr_box.col_min+1:col_max-curr_box.col_min+1) = 0;
  target_plane.images(imgnum).mytile_on_plane.orig_data(row_min-curr_box.row_min+1:row_max-curr_box.row_min+1, ... 
      col_min-curr_box.col_min+1:col_max-curr_box.col_min+1,:) = 0;


  cropped_box = target_plane.images(imgnum).mytile_on_plane.cropped_box;
  cropped_row_min = min(max(1, row_min - cropped_box.row_min+1),cropped_box.row_max-cropped_box.row_min+1);
  cropped_row_max = min(max(1, row_max - cropped_box.row_min+1),cropped_box.row_max-cropped_box.row_min+1);
  cropped_col_min = min(max(1, col_min - cropped_box.col_min+1),cropped_box.col_max-cropped_box.col_min+1);
  cropped_col_max = min(max(1, col_max - cropped_box.col_min+1),cropped_box.col_max-cropped_box.col_min+1);
  target_plane.images(imgnum).mytile_on_plane.cropped_valid(cropped_row_min:cropped_row_max, ... 
      cropped_col_min:cropped_col_max) = 0;
  target_plane.images(imgnum).mytile_on_plane.cropped_data(cropped_row_min:cropped_row_max, ... 
      cropped_col_min:cropped_col_max,:) = 0;
end

function fillRectangleWithData(target_plane, imgnum, row_min, row_max, col_min, col_max, data)
  curr_box = target_plane.images(imgnum).mytile_on_plane.orig_box;
  orig_row_min = row_min-curr_box.row_min+1;
  orig_row_max = row_max-curr_box.row_min+1;
  orig_col_min = col_min-curr_box.col_min+1;
  orig_col_max = col_max-curr_box.col_min+1;
  target_plane.images(imgnum).mytile_on_plane.orig_valid(orig_row_min:orig_row_max, ... 
      orig_col_min:orig_col_max) = (sum(data,3)~=0);
  target_plane.images(imgnum).mytile_on_plane.orig_data(orig_row_min:orig_row_max, ... 
      orig_col_min:orig_col_max,:) = data;


  %cropped_box = target_plane.images(imgnum).mytile_on_plane.cropped_box;
  %cropped_row_min = min(max(1, row_min - cropped_box.row_min+1),cropped_box.row_max-cropped_box.row_min+1);
  %cropped_row_max = min(max(1, row_max - cropped_box.row_min+1),cropped_box.row_max-cropped_box.row_min+1);
  %cropped_col_min = min(max(1, col_min - cropped_box.col_min+1),cropped_box.col_max-cropped_box.col_min+1);
  %cropped_col_max = min(max(1, col_max - cropped_box.col_min+1),cropped_box.col_max-cropped_box.col_min+1);
  %cropped_data = data(cropped_row_min-orig_row_min+1:end-(orig_row_max-cropped_row_max),...
  %    cropped_col_min-orig_col_min+1:end-(orig_col_max-cropped_col_max));
  %
  %target_plane.images(imgnum).mytile_on_plane.cropped_valid(cropped_row_min:cropped_row_max, ... 
  %    cropped_col_min:cropped_col_max) = (sum(cropped_data,3)~=0);
  %target_plane.images(imgnum).mytile_on_plane.cropped_data(cropped_row_min:cropped_row_max, ... 
  %    cropped_col_min:cropped_col_max,:) = cropped_data;
end



function occludeTriangle(corner, target_plane, imgnum, row_min, row_max, col_min, col_max)
  curr_box = target_plane.images(imgnum).mytile_on_plane.orig_box;
  % first create a patch with lower-right occluded, then flip as needed
  patch = ones(row_max-row_min+1,col_max-col_min+1);
  
  h = round(size(patch,1)/1);
  w = round(size(patch,2)/1);
  
  % this method is fancier, but probably slower
  %x = 1:w;
  %i = round(h * (x-1) + h - ((h-1)/w) * x);
  %patch(i) = 0;
  %horiz_fill = ones(1,col_max-col_min+1);
  %temp_patch = patch;
  %for hh = 1:h
  %    temp_patch = [temp_patch(2:row_max,:);horiz_fill];
  %    patch = patch & temp_patch;
  %end
  
  for ww = 1:w
      depth = round(h - ((h-1)/w) * ww);
      patch(1:depth,ww) = 0;
  end
  % what we have done is the LR case
  if strcmp(corner, 'LL')
      patch = fliplr(patch);
  elseif strcmp(corner, 'UL')
      patch = fliplr(patch);
      patch = flipud(patch);
  elseif strcmp(corner, 'UR')
      patch = flipud(patch);
  end
  

  temp = target_plane.images(imgnum).mytile_on_plane.orig_valid(row_min-curr_box.row_min+1:row_max-curr_box.row_min+1, ... 
      col_min-curr_box.col_min+1:col_max-curr_box.col_min+1);
  temp(logical(patch)) = 0;
  target_plane.images(imgnum).mytile_on_plane.orig_valid(row_min-curr_box.row_min+1:row_max-curr_box.row_min+1, ... 
      col_min-curr_box.col_min+1:col_max-curr_box.col_min+1) = temp;
  
  temp = target_plane.images(imgnum).mytile_on_plane.orig_data(row_min-curr_box.row_min+1:row_max-curr_box.row_min+1, ... 
      col_min-curr_box.col_min+1:col_max-curr_box.col_min+1,:);
  temp(logical(repmat(patch,[1,1,3]))) = 0;
  target_plane.images(imgnum).mytile_on_plane.orig_data(row_min-curr_box.row_min+1:row_max-curr_box.row_min+1, ... 
      col_min-curr_box.col_min+1:col_max-curr_box.col_min+1,:) = temp;


  cropped_box = target_plane.images(imgnum).mytile_on_plane.cropped_box;
  cropped_row_min = min(max(1, row_min - cropped_box.row_min+1),cropped_box.row_max-cropped_box.row_min+1);
  cropped_row_max = min(max(1, row_max - cropped_box.row_min+1),cropped_box.row_max-cropped_box.row_min+1);
  cropped_col_min = min(max(1, col_min - cropped_box.col_min+1),cropped_box.col_max-cropped_box.col_min+1);
  cropped_col_max = min(max(1, col_max - cropped_box.col_min+1),cropped_box.col_max-cropped_box.col_min+1);
  patch = zeros(cropped_row_max-cropped_row_min+1,cropped_col_max-cropped_col_min+1);
  h = size(patch,1);
  w = size(patch,2);

  for ww = 1:w
      depth = round(h - ((h-1)/w) * ww);
      patch(1:depth,ww) = 1;
  end
  % what we have done is the UL case
  if strcmp(corner, 'UR')
      patch = fliplr(patch);
  elseif strcmp(corner, 'LR')
      patch = rot90(patch,2);
  elseif strcmp(corner, 'LL')
      patch = flipud(patch);
  end
  
  temp = target_plane.images(imgnum).mytile_on_plane.cropped_valid(cropped_row_min:cropped_row_max, ... 
      cropped_col_min:cropped_col_max);
  temp(logical(patch)) = 0;
  target_plane.images(imgnum).mytile_on_plane.cropped_valid(cropped_row_min:cropped_row_max, ... 
      cropped_col_min:cropped_col_max) = temp;
  
  temp = target_plane.images(imgnum).mytile_on_plane.cropped_data(cropped_row_min:cropped_row_max, ... 
      cropped_col_min:cropped_col_max,:);
  temp(logical(repmat(patch,[1,1,3]))) = 0;
  target_plane.images(imgnum).mytile_on_plane.cropped_data(cropped_row_min:cropped_row_max, ... 
      cropped_col_min:cropped_col_max,:) = temp;
end

%liberally copied from stewart's occlusion check in Plane::occlusionCheck
function occluded = isoccluded(dest, source, planes, plane_to_ignore)
    occluded = false;
    dir = dest - source;
    for i = 1:size(planes,2)
        if i == plane_to_ignore
            % don't test occlusion with self
            continue;
        end
        p = planes(i);
        if sum(p.normal == [0;0;1])==3 || sum(p.normal == [0;0;-1])==3
            % sometimes we don't do intersection test with floors/ceilings,
            % when we have weird cases with multiple ceilings. skip such
            % tests by uncommenting the following continue statement
            % continue;
        end
        % find intersection between line and unbounded plane
        % n dot v = d where n is normal, d is plane offset
        % so n dot (center + dir*t) = d
        nDotCenter = dot(p.normal, source);
        nDotDir = dot(p.normal, dir);
        t = (-p.d - nDotCenter)/nDotDir;
        pointOfIntersection = source + dir * t;
        if (t <= 0) || (t >= 1)
            % doesn't come between our dest and source
            continue;
        end
        % now project to 2d and count number of times ray intersects plane
        % boundary.
        [checkPoint, delimitingPoints] = project_2d(p, pointOfIntersection);
        if polygonCheck(checkPoint, delimitingPoints)
            occluded = true;
        end
        if occluded
            break;
        end
    end
end

function [point_2d, plane_points_2d] = project_2d(plane_3d, point_3d)
  nx = plane_3d.normal(1);
  ny = plane_3d.normal(2);
  nz = plane_3d.normal(3);
  if (abs(nz) > abs(nx)) && (abs(nz) > abs(ny))
      index1 = 1;
      index2 = 2;
  elseif (abs(ny) > abs(nx))
      index1 = 1;
      index2 = 3;
  else
      index1 = 2;
      index2 = 3;
  end
  xp = point_3d(index1);
  yp = point_3d(index2);
  plane_points_2d = zeros(2,size(plane_3d.vertices,2));
  for j = 1:size(plane_3d.vertices,2)
     plane_points_2d(1,j) = plane_3d.vertices(index1,j);
     plane_points_2d(2,j) = plane_3d.vertices(index2,j);
  end
  point_2d = [xp,yp];
end

function inside = polygonCheck(checkPoint, points)
  % odd number of crossings means inside
  x = checkPoint(1);
  y = checkPoint(2);
  numIntersects = 0;
  inside = false;
  j = size(points,2);
  for i = 1:size(points,2)
      if (((points(2,i) > y) ~= (points(2,j) > y)) && ...
              (x < (points(1,j) - points(1,i)) * (y - points(2,i)) / (points(2,j) - points(2,i)) + points(1,i)))
          inside = ~inside;
          numIntersects = numIntersects + 1;
      end
      j = i;
  end
end