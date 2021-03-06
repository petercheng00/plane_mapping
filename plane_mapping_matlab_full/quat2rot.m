% used to get the rotation matrix from quaternions, e.g., R = quat2rot(Rq).

function R = quat2rot(q)


    q=q./(sqrt(sum(q.*q)));
    sqw=q(1)*q(1);
    sqx=q(2)*q(2);
    sqy=q(3)*q(3);
    sqz=q(4)*q(4);

    R=zeros(3);
    R(1,1)= sqx - sqy - sqz + sqw;
    R(2,2)= -sqx + sqy - sqz + sqw;
    R(3,3)= -sqx - sqy + sqz + sqw;

    tmp1=q(2)*q(3); 
    tmp2=q(4)*q(1); 
    R(2,1)= 2.0 * (tmp1 + tmp2);
    R(1,2)= 2.0 * (tmp1 - tmp2);

    tmp1=q(2)*q(4); 
    tmp2=q(3)*q(1); 

    R(3,1) = 2.0 * (tmp1 - tmp2);
    R(1,3) = 2.0 * (tmp1 + tmp2);

    tmp1=q(3)*q(4); 
    tmp2=q(2)*q(1); 

    R(3,2) = 2.0 * (tmp1 + tmp2);
    R(2,3) = 2.0 * (tmp1 - tmp2);

end