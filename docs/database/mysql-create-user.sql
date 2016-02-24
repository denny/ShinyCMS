CREATE USER 'shinyuser'@'%' IDENTIFIED BY 'shinypass';
GRANT ALL PRIVILEGES ON *.* TO 'shinyuser'@'%' WITH GRANT OPTION;

