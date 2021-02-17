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
Title varchar(20),
Caption varchar(200),
Image_Link varchar(100) default "",
upVotes int default 0,
downVotes int default 0,
timePosted timestamp DEFAULT CURRENT_TIMESTAMP,
foreign key(User_Id) references users(User_Id));

create table comments ( Comment_Id int auto_increment primary key,
Post_Id int,
User_Id varchar(40),
Comment varchar(80),
up_level_cid int default null,
upVotes int default 0,
downVotes int default 0,
timeCommented timestamp DEFAULT CURRENT_TIMESTAMP,
foreign key(Post_Id) references posts(Post_Id),
foreign key(User_Id) references users(user_Id),
foreign key(up_level_cid) references comments(Comment_Id));

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


delimiter //
create trigger after_comment_insert after insert
on comments
for each row
begin
update users set points=points+2 where user_id like new.user_id;
end //


delimiter //
create trigger after_postud_delete after delete
on userPostUd
for each row
begin
update users set points=points-1 where user_id like old.user_id;
if old.upOrDown like 'u' then
update posts set upvotes=upvotes-1 where user_id like old.user_id and post_id=old.post_id;
else
update posts set downvotes=downvotes-1 where user_id like old.user_id and post_id=old.post_id;
end if;
end //


delimiter //
create trigger after_postud_insert after insert
on userPostUd
for each row
begin
update users set points=points+1 where user_id like new.user_id;
if new.upOrDown like 'u' then
update posts set upvotes=upvotes+1 where user_id like new.user_id and post_id=new.post_id;
else
update posts set downvotes=downvotes+1 where user_id like new.user_id and post_id=new.post_id;
end if;
end //


delimiter //
create trigger after_postud_update after update
on userPostUd
for each row
begin
set SQL_SAFE_UPDATES=0;
if new.upOrDown like 'u' then
update posts set upvotes=upvotes-1,downvotes=downvotes+1 where user_id like old.user_id and post_id=old.post_id;
else 
update posts set downvotes=downvotes-1,upvotes=upvotes+1 where user_id like old.user_id and post_id=old.post_id;
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

delimiter //
create trigger after_commentUD_insert after insert
on userCommentUd
for each row
begin
update users set points=points+1 where user_id like new.user_id;
if new.upOrDown like 'u' then
update comments set upvotes=upvotes+1 where user_id like new.user_id and comment_id=new.comment_id;
else 
update comments set downvotes=downvotes+1 where user_id like new.user_id and comment_id=new.comment_id;
end if;
end // 


delimiter //
create trigger after_commentUD_update after update
on userCommentUd
for each row
begin
if new.upOrDown like 'u' then
update comments set upvotes=upvotes-1,downvotes=downvotes+1 where user_id like old.user_id and comment_id=old.comment_id;
else 
update comments set downvotes=downvotes-1,upvotes=upvotes+1 where user_id like old.user_id and comment_id=old.comment_id;
end if;
end //

delimiter //
create trigger after_commentUD_delete after delete
on userCommentUd
for each row
begin
update users set points=points-1 where user_id like old.user_id;
if old.upOrDown like 'u' then
update comments set upvotes=upvotes-1 where user_id like old.user_id and comment_id=old.comment_id;
else
update comments set downvotes=downvotes-1 where user_id like old.user_id and comment_id=old.comment_id;
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


