package main

import (
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"gamevault-backend/controllers"
	"gamevault-backend/database"
)

func main() {
	_ = godotenv.Load("config.env")

	database.Connect()

	r := gin.Default()

	r.GET("/games", controllers.ListGames)
	r.GET("/games/:id", controllers.GetGame)
	r.POST("/games", controllers.CreateGame)
	r.PUT("/games/:id", controllers.UpdateGame)
	r.DELETE("/games/:id", controllers.DeleteGame)

	if err := r.Run(":8080"); err != nil {
		panic(err)
	}
}
