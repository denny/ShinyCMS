CREATE USER 'shinyuser'@'%' IDENTIFIED BY 'shinypass';
GRANT ALL PRIVILEGES ON shinycms.* TO 'shinyuser'@'%' WITH GRANT OPTION;

