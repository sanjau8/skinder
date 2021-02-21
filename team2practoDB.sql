use redClone;


------------------------------------------------------------------------------


create table users ( User_Id varchar(40) primary key,
Name varchar(30),
Image_Link varchar(200),
Email varchar(30) unique key,
Points int default 0,
joinedOn timestamp DEFAULT CURRENT_TIMESTAMP);




create table posts (Post_Id int auto_increment primary key,
User_Id varchar(40),
Title varchar(150),
Caption varchar(500),
Image_Link varchar(100) default "",
upVotes int default 0,
downVotes int default 0,
noOfComments int default 0,
timePosted timestamp DEFAULT CURRENT_TIMESTAMP,
foreign key(User_Id) references users(User_Id));

alter table posts add column noOfComments int default 0;

alter table posts modify column title varchar(150);
alter table posts modify column caption varchar(500);

select * from comments;
update posts set noOfComments=4 where post_id=1;
update posts set noOfComments=1 where post_id=4;

create table comments ( Comment_Id int auto_increment primary key,
Post_Id int,
User_Id varchar(40),
Comment varchar(80),
up_level_cid int default null,
upVotes int default 0,
downVotes int default 0,
timeCommented timestamp DEFAULT CURRENT_TIMESTAMP,
noOfThreads int default 0,
foreign key(Post_Id) references posts(Post_Id),
foreign key(User_Id) references users(user_Id),
foreign key(up_level_cid) references comments(Comment_Id));


alter table comments add column noOfThreads int default 0;

create table userPostUd (Post_Id int,
User_Id varchar(40),
upOrDown varchar(1),
primary key(Post_Id,User_Id),
foreign key(User_Id) references users(User_Id),
foreign key(Post_Id) references posts(Post_Id));

create table userCommentUd (Comment_id int,
User_id varchar(40),
upOrDown varchar(1),
primary key(Comment_id,User_id),
foreign key(User_id) references users(User_id),
foreign key(Comment_id) references comments(Comment_id));

create table userjwt (User_id varchar(40) primary key,
refreshToken varchar(800));

create table postBackup( timeBackedUp timestamp default current_timestamp,
post_id int,
upVotes int,
downVotes int,
foreign key(post_id) references posts(post_id));

------------------------------------------------------------------------------------------------
drop table postBackup;
select CURRENT_DATE;

drop trigger after_posts_insert;
drop trigger after_comment_insert;
drop trigger after_postud_delete;
drop trigger after_postud_insert;
drop trigger after_postud_update;

delimiter //
create trigger after_posts_insert after insert
on posts
for each row
begin
update users set points=points+5 where user_id like new.user_id;
end //

drop trigger after_comment_insert;

delimiter //
create trigger after_comment_insert after insert
on comments
for each row
begin
update users set points=points+2 where user_id like new.user_id;
update posts set noOfComments=noOfComments+1 where post_id=new.post_id;
end //

drop trigger after_postud_delete;
delimiter //
create trigger after_postud_delete after delete
on userPostUd
for each row
begin
update users set points=points-1 where user_id like old.user_id;
if old.upOrDown like 'u' then
update posts set upvotes=upvotes-1 where post_id=old.post_id;
else
update posts set downvotes=downvotes-1 where post_id=old.post_id;
end if;
end //

drop trigger after_postud_insert
delimiter //
create trigger after_postud_insert after insert
on userPostUd
for each row
begin
update users set points=points+1 where user_id like new.user_id;
if new.upOrDown like 'u' then
update posts set upvotes=upvotes+1 where post_id=new.post_id;
else
update posts set downvotes=downvotes+1 where post_id=new.post_id;
end if;
end //

drop trigger after_postud_update
delimiter //
create trigger after_postud_update after update
on userPostUd
for each row
begin
set SQL_SAFE_UPDATES=0;
if new.upOrDown like 'u' then
update posts set upvotes=upvotes+1,downvotes=downvotes-1 where post_id=old.post_id;
else 
update posts set downvotes=downvotes+1,upvotes=upvotes-1 where post_id=old.post_id;
end if;
end // 


delimiter //
CREATE PROCEDURE `interactPost` (IN u_id varchar(100),IN p_id int,IN UorD varchar(100))
BEGIN
	declare vote varchar(100) default 'u';
	IF exists(select * from userPostUd where post_id=p_id and user_id=u_id) then
		select lower(upOrDown) into vote from userPostUd where user_id=u_id and post_id=p_id;
			if vote like UorD then
				delete from userPostUd where user_id=u_id and post_id=p_id;
			else
				update userPostUd set upOrDown=UorD where post_id=p_id and user_id=u_id;
			end if;
	else
		insert into userPostUd values(p_id,u_id,UorD);
	end if;
END //
drop procedure `interactPost`;

drop trigger after_commentUD_insert
delimiter //
create trigger after_commentUD_insert after insert
on userCommentUd
for each row
begin
update users set points=points+1 where user_id like new.user_id;
if new.upOrDown like 'u' then
update comments set upvotes=upvotes+1 where comment_id=new.comment_id;
else 
update comments set downvotes=downvotes+1 where comment_id=new.comment_id;
end if;
end // 

drop trigger after_commentUD_update
delimiter //
create trigger after_commentUD_update after update
on userCommentUd
for each row
begin
if new.upOrDown like 'u' then
update comments set upvotes=upvotes+1,downvotes=downvotes-1 where comment_id=old.comment_id;
else 
update comments set downvotes=downvotes+1,upvotes=upvotes-1 where comment_id=old.comment_id;
end if;
end //

drop trigger after_commentUD_delete
delimiter //
create trigger after_commentUD_delete after delete
on userCommentUd
for each row
begin
update users set points=points-1 where user_id like old.user_id;
if old.upOrDown like 'u' then
update comments set upvotes=upvotes-1 where comment_id=old.comment_id;
else
update comments set downvotes=downvotes-1 where comment_id=old.comment_id;
end if;
end //


delimiter //
CREATE  PROCEDURE `interactComment`(IN u_id varchar(100),IN c_id int,IN UorD varchar(100))
BEGIN
	declare vote varchar(100) default 'u';
	IF exists(select * from userCommentUd where comment_id=c_id and user_id=u_id) then
		select upOrDown into vote from userCommentUd where user_id=u_id and comment_id=c_id;
			if vote like UorD then
				delete from userCommentUd where user_id=u_id and comment_id=c_id;
			else
				update userCommentUd set UorD=UorD where comment_id=c_id and user_id=u_id;
			end if;
	else
		insert into userCommentUd values(c_id,u_id,UorD);
	end if;
END //


delimiter //
create event if not exists backupPosts
on schedule every 1 hour
on completion preserve
do 
begin
delete from postBackup as b where b.timeBackedUp<date_sub(now(),interval 3 hour);
insert into postBackup(post_id,upvotes,downvotes) select post_id,upvotes,downvotes from posts;
end //


drop event backupPosts;
select * from postBackup;


drop procedure interactComment;

update comments set upvotes=0 where comment_id=1
call interactComment("109165885006154115400",1,'u')
select * from comments;
delete from userCommentUd where user_id="109165885006154115400";
select * from userCommentUd
select * from userPostUd;

update users set points=0 where user_id="109165885006154115400";
update posts set upvotes=1 where post_id=1;
select * from userjwt;
delete from userjwt where user_id="117467032651053987701";
delete from users where User_id="";
select * from users;
select * from posts;
select * from userPostUd;
call interactPost("109165885006154115400",1,'u');

update users set points=0 where user_id="109165885006154115400";
update users set joinedOn="2021-02-14 13:45" where user_id="117467032651053987701";

select temp.*,up.upordown from (select p.*,u.name,u.image_link as user_image from posts as p,users as u where p.user_id=u.user_id) as temp left join userPostUd as up on temp.post_id=up.post_id where up.user_id="117467032651053987701"; 

select temp.*,u.name,u.image_link as user_image from (select p.*,up.upordown from (select * from posts where user_id="109165885006154115400") as p LEFT JOIN (select post_id,upordown from userPostUd where user_id="109165885006154115400") as up on p.post_id=up.post_id)as temp,users as u where temp.user_id=u.user_id order by temp.timePosted desc;

insert into userPostUd values(1,"109165885006154115400",'U');

select p.*,u.image_link as user_image,u.name from posts as p,users as u where p.user_id=u.user_id  order by upvotes+downvotes desc;

update posts set upvotes=2 where post_id=1;
update posts set downvotes=3 where post_id=2;

insert into userCommentUd values(1,"109165885006154115400",'u')
select temp.*,u.name,u.image_link as user_image from (select p.*,up.upordown from comments as p LEFT JOIN (select comment_id,upordown from userCommentUd where user_id="117467032651053987701") as up on p.comment_id=up.comment_id)as temp,users as u where temp.user_id=u.user_id and temp.up_level_cid is null and post_id=2 order by temp.timeCommented desc

SET time_zone = "+5:30";
select CURRENT_TIMESTAMP;

ALTER TABLE users MODIFY joinedOn TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;
ALTER TABLE posts MODIFY timePosted TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;
ALTER TABLE comments MODIFY timeCommented TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL;

select * from posts;
select * from users;

select temp1.*,u.image_link as user_image,u.name from (select p.post_id,p.user_id,p.title,p.caption,p.image_link,DATE_FORMAT(p.timeposted, "%H:%i %d-%m-%Y") as timeposted,p.upvotes-coalesce(temp.upvotes,0)+p.downvotes-coalesce(temp.downvotes,0) as total from posts as p left join (select timeBackedup,post_id,upvotes,downvotes from postBackup where timeBackedUp<date_sub(now(),interval 3 hour)) as temp on p.post_id=temp.post_id) as temp1,users as u where temp1.user_id=u.user_id and total>0 order by total desc;

call interactPost("108067550179259097224",2,'d');
select * from userPostUd

update posts set downvotes=1 where post_id =10
select * from postBackup;

 call interactPost("109165885006154115400",9,'d')
 
 insert into comments(user_id,post_id,comment) values ("109165885006154115400",11,"oh yes its working");
 
 select * from comments ;
 delete from comments where post_id is null;
 select * from posts;
 select temp1.*,u.image_link as user_image,u.name from (select p.post_id,p.user_id,p.title,p.caption,p.image_link,DATE_FORMAT(p.timeposted, "%H:%i %d-%m-%Y") as timeposted,p.upvotes-coalesce(temp.upvotes,0)+p.downvotes-coalesce(temp.downvotes,0) as total from posts as p left join (select timeBackedup,post_id,upvotes,downvotes from postBackup where timeBackedUp<date_sub(now(),interval 3 hour)) as temp on p.post_id=temp.post_id) as temp1,users as u where temp1.user_id=u.user_id and total>0 order by total desc;



select p.post_id,p.user_id,p.title,p.caption,p.image_link,p.upvotes,p.downvotes,p.noofcomments,DATE_FORMAT(p.timeposted, "%H:%i %d-%m-%Y") as timeposted,u.image_link as user_image,u.name from posts as p,users as u where p.user_id=u.user_id  and upvotes+downvotes>0 order by upvotes+downvotes desc

select temp.*,u.name,u.image_link as user_image from (select p.post_id,p.user_id,p.title,p.caption,p.image_link,p.upvotes,p.downvotes,DATE_FORMAT(p.timeposted, "%H:%i %d-%m-%Y") as timeposted,coalesce(up.upordown,"") as upordown from posts as p LEFT JOIN (select post_id,upordown from userPostUd where user_id="109165885006154115400") as up on p.post_id=up.post_id)as temp,users as u where temp.user_id=u.user_id order by post_id desc

update posts set upvotes=1 where post_id=11;

select * from userPostUd;
select * from posts;

call interactPost("101300573873600641559",11,'u')

insert into comments(post_id,user_id,comment) values (13,"108067550179259097224","But i hate coffee yuck");
insert into comments(post_id,user_id,comment) values (13,"109165885006154115400","tea is love");

insert into comments(post_id,user_id,comment) values (14,"108067550179259097224","oh is it?");
insert into comments(post_id,user_id,comment) values (14,"109165885006154115400","what could i understand from this?");


select temp.*,u.name,u.image_link as user_image from (select p.post_id,p.user_id,p.title,p.caption,p.image_link,p.upvotes,p.downvotes,p.noofcomments,DATE_FORMAT(p.timeposted, "%H:%i %d-%m-%Y") as timeposted,coalesce(up.upordown,"") as upordown from posts as p LEFT JOIN (select post_id,upordown from userPostUd where user_id="109165885006154115400") as up on p.post_id=up.post_id)as temp,users as u where temp.user_id=u.user_id and upvotes+downvotes>0 order by upvotes+downvotes desc

select temp.*,u.name,u.image_link as user_image from (select p.comment_id,p.post_id,p.user_id,p.comment,p.upVotes,p.downVotes,DATE_FORMAT(p.timecommented, "%H:%i %d-%m-%Y") as timeCommented,p.up_level_cid,coalesce(up.upordown,"") as upordown from comments as p LEFT JOIN (select comment_id,upordown from userCommentUd where user_id="109165885006154115400") as up on p.comment_id=up.comment_id)as temp,users as u where temp.user_id=u.user_id and temp.up_level_cid is null and post_id=1 order by comment_id desc



select temp.*,u.name,u.image_link as user_image from (select p.comment_id,p.post_id,p.user_id,p.comment,p.upVotes,p.downVotes,DATE_FORMAT(p.timecommented, "%H:%i %d-%m-%Y") as timeCommented,p.up_level_cid,coalesce(up.upordown,"") as upordown from comments as p LEFT JOIN (select comment_id,upordown from userCommentUd where user_id="${uid}") as up on p.comment_id=up.comment_id)as temp,users as u where temp.user_id=u.user_id and temp.up_level_cid is null and post_id=${pid} order by comment_id desc


select * from posts;
select * from userPostUd;

update posts set upvotes=1, downvotes=0 where post_id=5;
update posts set upvotes=1, downvotes=0 where post_id=6;
update posts set upvotes=1, downvotes=0 where post_id=7;


update userPostUd set upordown='u' where post_id=5;
update userPostUd set upordown='u' where post_id=6;
update userPostUd set upordown='u' where post_id=7;


select * from userPostUd;


delete from posts where post_id>18;

delete from postBackup where post_id>18;

select * from posts;

select * from comments;

delete from comments where post_id is null;

update posts set upvotes=1, downvotes=1 where post_id=14;


select * from users;
select temp.*,u.name,u.image_link as user_image from (select p.post_id,p.user_id,p.title,p.caption,p.image_link,p.upvotes,p.downvotes,p.noofcomments,DATE_FORMAT(p.timeposted, "%H:%i %d-%m-%Y") as timeposted,coalesce(up.upordown,"") as upordown from (select post_id,user_id,title,caption,image_link,upvotes,downvotes,noofcomments,timeposted from posts where user_id="109165885006154115400") as p LEFT JOIN (select post_id,upordown from userPostUd where user_id="109165885006154115400") as up on p.post_id=up.post_id)as temp,users as u where temp.user_id=u.user_id order by post_id desc

select temp2.*,u.image_link as user_image,u.name from (select temp1.*,coalesce(up.upordown,"") as upordown from (select p.post_id,p.user_id,p.title,p.caption,p.image_link,p.upvotes,p.downvotes,p.noofcomments,DATE_FORMAT(p.timeposted, "%H:%i %d-%m-%Y") as timeposted,p.upvotes-coalesce(temp.upvotes,0)+p.downvotes-coalesce(temp.downvotes,0) as total from posts as p left join (select timeBackedup,post_id,upvotes,downvotes from postBackup where timeBackedUp<date_sub(now(),interval 3 hour)) as temp on p.post_id=temp.post_id) as temp1 LEFT JOIN (select post_id,upordown from userPostUd where user_id="109165885006154115400") as up on temp1.post_id=up.post_id) as temp2 ,users as u where temp2.user_id=u.user_id and total>0 order by total desc;