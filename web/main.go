package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"

	"gamevault-web/controllers"
)

func main() {
	_ = godotenv.Load("config.env")

	r := gin.Default()
	r.LoadHTMLGlob("templates/*")
	r.Static("/static", "./static")

	r.GET("/", controllers.RenderIndex)

	port := os.Getenv("WEB_PORT")
	if port == "" {
		port = "3000"
	}

	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
