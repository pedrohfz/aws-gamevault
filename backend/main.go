package main

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"gamevault-backend/controllers"
	"gamevault-backend/database"
)

func main() {
	_ = godotenv.Load("config.env")

	database.Connect()

	r := gin.Default()

	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept"},
		AllowCredentials: false,
	}))

	r.GET("/games", controllers.ListGames)
	r.GET("/games/:id", controllers.GetGame)
	r.POST("/games", controllers.CreateGame)
	r.PUT("/games/:id", controllers.UpdateGame)
	r.DELETE("/games/:id", controllers.DeleteGame)

	r.GET("/report", controllers.GenerateReport)

	if err := r.Run(":8080"); err != nil {
		panic(err)
	}
}
