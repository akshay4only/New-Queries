
delete hfc_user_master_stag;

insert into hfc_user_master_stag(empcode,domain_id,employee_name,doj,department,designation,product,branch, jmfl_email_id,mobile,ed,status, coed,dor, lwd,telephone_no,extension_no, gender,payroll)
select trim(u.empcode),
       upper(trim(u.usercode)),
       upper(trim(u.name)),
       to_date(trim(u.dateofjoining), 'YYYY-MM-DD'),
       upper(trim(u.department)),
       upper(trim(u.designation)),
       upper(trim(u.product)),
       upper(trim(u.branch)),
       (case when upper(trim(u.email)) <> 'NA' then upper(trim(u.email)) end),
       trim(u.mobile),
       trim(u.managercode),
       decode(upper(trim(u.status)),'ACTIVE','Y','N'),
       replace(trim(u.coed), 'NULL', ''),
       to_date(replace(trim(u.dor), 'NULL', ''), 'YYYY-MM-DD'),
       to_date(replace(trim(u.lwd), 'NULL', ''), 'YYYY-MM-DD'),
       trim(u.telephone_no),
       trim(u.extension_no),
       upper(trim(u.gender)),
       upper(trim(u.payroll))
  from hfc_user_master_upload u;

insert into hfc_user_master(employee_code,employee_name,branch,jmfl_email_id,mobile_no,domain_id,is_active,doj,function,product,designation,ed,coed,payroll,dor,lwd,telephone_no, extension_no,gender,gender_class)
select s.empcode,
       s.employee_name,
       s.branch,
       s.jmfl_email_id,
       s.mobile,
       s.domain_id,
       s.status,
       s.doj,
       s.department,
       s.product,
       s.designation,
       s.ed,
       s.coed,
       s.payroll,
       s.dor,
       s.lwd,
       s.telephone_no,
       s.extension_no,
       s.gender,
       decode(s.gender, 'MALE', 'fa fa-male', 'fa fa-female')
  from hfc_user_master_stag s
 where not exists (select 1
          from hfc_user_master um
         where um.employee_code = s.empcode
           and upper(um.domain_id) = upper(s.domain_id))
     

DECLARE
CURSOR NEW_RECORDS
is
select a.*,
(select distinct 'Y' from qc_master.qm_salesmanager@MIFIN_PROD sm where sm.salesmanagercode = a.employee_code) sm_exists_in_mifin,
(select distinct 'Y' from qc_master.qm_agentmaster@MIFIN_PROD agt where agt.agentmastercode = a.employee_code) dst_exists_in_mifin
 from (
select u.employee_code,
       u.employee_name,
       u.doj,
       u.jmfl_email_id,
       u.branch,
       (SELECT G.GEOID FROM QC_MASTER.QM_GEO@MIFIN_PROD G WHERE UPPER(G.DESCRIPTION) = UPPER(U.BRANCH)) MIFIN_BRANCH_ID,
       substr(u.mobile_no,1,10)mobile_no ,
       u.product,
       u.designation,
       decode(u.designation,
              'RELATIONSHIP MANAGER',
              'DST',
              'Relationship Manager',
              'DST',
              'SENIOR RELATIONSHIP MANAGER',
              'DST',
              'Senior Relationship Manager',
              'DST',
              'SALES COORDINATOR',
              'OTHERS',
              'Sales Coordinator',
              'OTHERS',
              'Senior Executive',
              'OTHERS',
              'SM') miFIN_Design
  from hfc_user_master u
 where u.is_active = 'Y'
   and upper(u.function) like '%SALES%') a;
vn_id number;
vc_code varchar2(100);
vc_status varchar2(100);
vc_errcode varchar2(100);
 vc_errdesc varchar2(1000); 

vn_maker_id number := 1000000701;
vn_author_id number := 1000000578;
vd_date date;

begin
select to_date(sysc.paramvalue,'DD-Mon-YYYY')
  into vd_date
 from qc_user_auth.qm_sys_configuration sysc 
 where sysc.applicationname = 'LOS' 
 and sysc.paramname = 'BUSINESS DATE';

for i in NEW_RECORDS loop

if i.mifin_design = 'SM' and i.sm_exists_in_mifin is null
then
qc_master.pr_generate@mifin_prod(P_SEQUENCENAME => 'QM_SALESMANAGER',P_IDVALUE => vn_id,P_CODEVALUE => vc_code,P_STATUS => vc_status,P_ERROR_CODE => vc_errcode,P_ERROR_DESC => vc_errdesc);
insert into qc_master.qm_salesmanager@mifin_prod(
salesmanagerid,salesmanagercode,salesmanagername,salesmanagerdisplayname,description,location,active,maker_id,maker_date,maker_sysdate,maker_remarks,auth_id,auth_date,auth_sysdate,auth_remark,salesmanageremail,mobile_no)
values(
vn_id, i.employee_code, i.employee_name,i.employee_name, i.employee_name, i.mifin_branch_id, 'A',vn_maker_id, vd_Date, sysdate, 'sm configuration',vn_author_id, vd_Date, sysdate,'ok', i.jmfl_email_id, i.mobile_no );

if i.product = 'MSME' and i.dst_exists_in_mifin is null then
qc_master.pr_generate@mifin_prod(P_SEQUENCENAME => 'QM_AGENTMASTER',P_IDVALUE => vn_id,P_CODEVALUE => vc_code,P_STATUS => vc_status,P_ERROR_CODE => vc_errcode,P_ERROR_DESC => vc_errdesc);
insert into qc_master.qm_agentmaster@mifin_prod(
agentmasterid,agentmastercode,agentmastername,displayname,agencyid,active,agentmastermobile,agentmasteremail,maker_id,maker_date,maker_sysdate,maker_remarks,auth_id,auth_date,auth_sysdate,auth_remark)
values(
vn_id, i.employee_code,i.employee_name,i.employee_name,(select ag.agencymasterid from qc_master.qm_agencymaster@mifin_prod ag where ag.agencymastername = 'INTERNAL SALES_' || (select substr(g.geoname,1,3) from qc_master.qm_geo@mifin_prod g where g.geoid = i.MIFIN_BRANCH_ID)), 'A',i.mobile_no, i.jmfl_email_id ,vn_maker_id, vd_Date, sysdate, 'sm configuration',vn_author_id, vd_Date, sysdate,'ok'  );
end if;
end if;

if i.miFIN_Design = 'DST' and i.dst_exists_in_mifin is null then
qc_master.pr_generate@mifin_prod(P_SEQUENCENAME => 'QM_AGENTMASTER',P_IDVALUE => vn_id,P_CODEVALUE => vc_code,P_STATUS => vc_status,P_ERROR_CODE => vc_errcode,P_ERROR_DESC => vc_errdesc);
insert into qc_master.qm_agentmaster@mifin_prod(
agentmasterid,agentmastercode,agentmastername,displayname,agencyid,active,agentmastermobile,agentmasteremail,maker_id,maker_date,maker_sysdate,maker_remarks,auth_id,auth_date,auth_sysdate,auth_remark)
values(
vn_id, i.employee_code,i.employee_name,i.employee_name,(select ag.agencymasterid from qc_master.qm_agencymaster@mifin_prod ag where ag.agencymastername = 'INTERNAL SALES_' || (select substr(g.geoname,1,3) from qc_master.qm_geo@mifin_prod g where g.geoid = i.MIFIN_BRANCH_ID) and rownum =1), 'A', i.mobile_no, i.jmfl_email_id ,vn_maker_id, vd_Date, sysdate, 'dst configuration',vn_author_id, vd_Date, sysdate,'ok'  );
end if;

end loop;

end;

commit;

update hfc_user_master um
set um.is_active='N'
 where exists (select 1
          from hfc_user_master_stag st
         where st.empcode = um.employee_code
           and nvl(st.status,'N') = 'N')
and um.is_active ='Y';

commit;