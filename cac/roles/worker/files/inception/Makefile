VOLUMES = mariadb wordpress nginx phpmyadmin

all:
	@scripts/vol_create.sh $(VOLUMES)
	@docker-compose down --remove-orphans
	@docker-compose up -d --build

clean:
	@docker-compose down --rmi all --volumes --remove-orphans
	@scripts/vol_delete.sh "$(VOLUMES)"

fclean: clean
	@docker system prune -f --volumes

re: fclean all

info:
	@scripts/info.sh

.PHONY: all clean fclean re info
