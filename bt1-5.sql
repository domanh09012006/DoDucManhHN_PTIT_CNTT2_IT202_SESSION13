create database SS12_B1;
use SS12_B1;

create table users (
    user_id int auto_increment primary key,
    username varchar(50) not null unique,
    email varchar(100) not null unique,
    created_at date,
    follower_count int default 0,
    post_count int default 0
);
create table posts (
    post_id int auto_increment primary key,
    user_id int,
    content text,
    created_at datetime,
    like_count int default 0,
    constraint fk_posts_users foreign key (user_id) references users(user_id)
	on delete cascade
);
create table likes (
    like_id int auto_increment primary key,
    user_id int,
    post_id int,
    liked_at datetime default now(),
    constraint fk_likes_users foreign key (user_id) references users(user_id) on delete cascade,
    constraint fk_likes_posts foreign key (post_id) references posts(post_id) on delete cascade
);

create table post_history (
    history_id int auto_increment primary key,
    post_id int,
    old_content text,
    new_content text,
    changed_at datetime,
    changed_by_user_id int,
    constraint fk_history_posts foreign key (post_id) references posts(post_id) on delete cascade
);



insert into users (username, email, created_at) 
values('alice', 'alice@example.com', '2025-01-01'),
('bob', 'bob@example.com', '2025-01-02'),
('charlie', 'charlie@example.com', '2025-01-03');

-- ----------bai1:
delimiter //
create trigger tg_increase_post_count
after insert on posts
for each row
begin
    update users set post_count = post_count + 1 where user_id = new.user_id;
end//
delimiter ;

delimiter //
create trigger tg_decrease_post_count
after delete on posts
for each row
begin
    update users set post_count = post_count - 1 where user_id = old.user_id;
end//
delimiter ;

insert into posts (user_id, content, created_at) 
values(1, 'hello world from alice!', '2025-01-10 10:00:00'),
(1, 'second post by alice', '2025-01-10 12:00:00'),
(2, 'bob first post', '2025-01-11 09:00:00'),
(3, 'charlie sharing thoughts', '2025-01-12 15:00:00');

delete from posts where post_id = 2;
select * from users;

insert into likes (user_id, post_id, liked_at) 
values (2, 1, '2025-01-10 11:00:00'),
(3, 1, '2025-01-10 13:00:00'),
(1, 3, '2025-01-11 10:00:00'),
(3, 4, '2025-01-12 16:00:00');

-- ------------Bai 2:
delimiter //
create trigger tg_increase_like_count
after insert on likes
for each row
begin
    update posts set like_count = like_count + 1 where post_id = new.post_id;
end//
delimiter ;

delimiter //
create trigger tg_decrease_like_count
after delete on likes
for each row
begin
    update posts set like_count = like_count - 1 where post_id = old.post_id;
end//

delimiter ;
create view user_statistics as
select u.user_id, u.username, u.post_count, count(l.like_id) as total_like
from users u
left join posts p on u.user_id = p.user_id
left join likes l on p.post_id = l.post_id
group by u.user_id, u.username, u.post_count;

insert into likes (user_id, post_id, liked_at)
values (2, 4, now());

select * from posts where post_id = 4;
delete from likes
where user_id = 2 and post_id = 4;

select * from user_statistics;

-- ----------Bài 3:

-- ko cho like bài cua chinh minh
delimiter //
create trigger tg_check_self_like
before insert on likes
for each row
begin
    declare post_owner int;
    select user_id into post_owner from posts
    where post_id = new.post_id;

    if new.user_id = post_owner then
        signal sqlstate '45000'
        set message_text = 'khong duoc like bai dang cua chinh minh';
    end if;
end//
delimiter ;

-- tang like
delimiter //
create trigger tg_like_after_insert
after insert on likes
for each row
begin
    update posts set like_count = like_count+1 where post_id = new.post_id;
end//
delimiter ;

-- giam
delimiter //
create trigger tg_like_after_delete
after delete on likes
for each row
begin
    update posts set like_count = like_count-1 where post_id = old.post_id;
end//
delimiter ;

-- doi id
delimiter //
create trigger tg_like_after_update
after update on likes
for each row
begin
    if old.post_id <> new.post_id then
        update posts set like_count = like_count-1 where post_id = old.post_id;
        update posts set like_count = like_count+1 where post_id = new.post_id;
    end if;
end//
delimiter ;

-- kiem thu
insert into likes (user_id, post_id)
values (1, 1);

update likes set post_id = 3 where user_id = 2 and post_id = 1;
select post_id, like_count from posts where post_id in (1, 3);

delete from likes where user_id = 2 and post_id = 3;
select post_id, like_count from posts where post_id = 3;


-- --------Bài 4:
-- luu lich su
delimiter //
create trigger tg_log_post_update
before update on posts
for each row
begin
    if old.content <> new.content then
        insert into post_history (post_id, old_content, new_content, changed_at, changed_by_user_id)
        values(old.post_id, old.content, new.content, now(), old.user_id);
    end if;
end//
delimiter ;

-- update bai
update posts set content = 'noi dung da duoc chinh sua lan 1' where post_id = 1;
update posts set content = 'noi dung da duoc chinh sua lan 2' where post_id = 1;
select * from post_history where post_id = 1;

-- Bai 5

delimiter //
create procedure add_user(
    in p_username varchar(50),
    in p_email varchar(100),
    in p_created_at date
)
begin
    insert into users (username, email, created_at)
    values (p_username, p_email, p_created_at);
end//
delimiter ;

-- check user
delimiter //

create trigger tg_check_user_before_insert
before insert on users
for each row
begin
    if new.email not like '%@%.%' then
        signal sqlstate '45000'
        set message_text = 'email khong hop le';
    end if;

    -- kiem tra username (chi cho phep a-z, a-z, 0-9, _)
    if new.username not regexp '^[a-zA-Z0-9_]+$' then
        signal sqlstate '45000'
        set message_text = 'username chi duoc chua chu, so va dau gach duoi';
    end if;
end//
delimiter ;

delimiter //

create trigger tg_check_user_before_insert
before insert on users
for each row
begin
    if new.email not like '%@%' then
        signal sqlstate '45000'
        set message_text = 'email phai co dau @';
    end if;
    if new.email not like '%.%' then
        signal sqlstate '45000'
        set message_text = 'email phai co dau .';
    end if;
    if new.username like '% %' then
        signal sqlstate '45000'
        set message_text = 'username khong duoc chua dau cach';
    end if;
    if new.username like '%@%' then
        signal sqlstate '45000'
        set message_text = 'username khong duoc chua ky tu @';
    end if;
    if new.username like '%#%' then
        signal sqlstate '45000'
        set message_text = 'username khong duoc chua ky tu #';
    end if;
end//
delimiter ;
call add_user('user01', 'user01gmail.com', '2025-03-01');











