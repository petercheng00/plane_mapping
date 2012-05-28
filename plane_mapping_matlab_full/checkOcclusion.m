function checkOcclusion(planes, plane_index)
  target_plane = planes(plane_index);
  images = target_plane.images;
  for i = 1:size(images,2)
      camera_pt_world = images(i).t;
      
      curr_box = images(i).mytile_on_plane.box;
      gridStepY = 40;
      gridStepX = 40;
      numSectionsY = ceil((curr_box.row_max - curr_box.row_min + 1)/gridStepY);
      numSectionsX = ceil((curr_box.col_max - curr_box.col_min + 1)/gridStepX);
      for j = 1:numSectionsY
          for k = 1:numSectionsX
              row_min = curr_box.row_min + (j-1) * gridStepY;
              row_max = min(curr_box.row_min + (j * gridStepY), curr_box.row_max);
              col_min = curr_box.col_min + (k-1) * gridStepX;
              col_max = min(curr_box.col_min + (k * gridStepX), curr_box.col_max);
              
              center_pt_plane = [(row_max+row_min)/2; (col_max+col_min)/2];      
              center_pt_world = target_plane.get_world_pts(center_pt_plane);
              
              if isoccluded(center_pt_world, camera_pt_world, planes, plane_index)
                  %empty_patch = zeros(row_max-row_min+1,col_max-col_min+1,3);
                  %target_plane.images(i).mytile_on_plane.data(row_min-curr_box.row_min+1:row_max-curr_box.row_min+1, ... 
                  %    col_min-curr_box.col_min+1:col_max-curr_box.col_min+1,:) = empty_patch;
                  
                  %orig_box = images(i).mytile_on_plane.origbox;
                  %target_plane.images(i).mytile_on_plane.origdata(row_min-orig_box.row_min+1:row_max-orig_box.row_min+1, ... 
                  %    col_min-orig_box.col_min+1:col_max-orig_box.col_min+1,:) = empty_patch;
                  empty_patch = zeros(row_max-row_min+1,col_max-col_min+1);
                  target_plane.images(i).mytile_on_plane.isvalid(row_min-curr_box.row_min+1:row_max-curr_box.row_min+1, ... 
                      col_min-curr_box.col_min+1:col_max-curr_box.col_min+1) = empty_patch;
                  
                  % right now haven't handled cropping of origdata, not
                  % sure if it will be useful
                  orig_box = images(i).mytile_on_plane.origbox;
                  target_plane.images(i).mytile_on_plane.origisvalid(row_min-orig_box.row_min+1:row_max-orig_box.row_min+1, ... 
                      col_min-orig_box.col_min+1:col_max-orig_box.col_min+1) = empty_patch;

              end
          end
      end
      if sum(sum(target_plane.images(i).mytile_on_plane.isvalid)) > 0
          target_plane.images(i).mytile_on_plane = target_plane.images(i).mytile_on_plane.crop();
          target_plane.images(i).mytile_on_plane = target_plane.images(i).mytile_on_plane.set_border_mask(target_plane.blendpx);
      else
          target_plane.images(i).useful = false;
      end
  end


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
            % don't do intersection test with floors/ceilings, since often
            % we have weird cases with multiple ceilings
            continue;
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
        nx = p.normal(1);
        ny = p.normal(2);
        nz = p.normal(3);
        index1 = -1;
        index2 = -1;
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
        xp = pointOfIntersection(index1);
        yp = pointOfIntersection(index2);
        delimitingPoints = zeros(2,size(p.vertices,2));
        for j = 1:size(p.vertices,2)
           delimitingPoints(1,j) = p.vertices(index1,j);
           delimitingPoints(2,j) = p.vertices(index2,j);
        end
        checkPoint = [xp,yp];
        if polygonCheck(checkPoint, delimitingPoints)
            occluded = true;
        end
        if occluded
            break;
        end
    end
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