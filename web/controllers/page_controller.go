package controllers

import (
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

func RenderIndex(c *gin.Context) {
	apiURL := os.Getenv("API_GATEWAY_URL")
	if apiURL == "" {
		apiURL = "http://localhost:8080"
	}

	c.HTML(http.StatusOK, "index.html", gin.H{
		"APIGatewayURL": apiURL,
	})
}
