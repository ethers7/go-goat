package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestMain(m *testing.M) {
	gin.SetMode(gin.TestMode)
	m.Run()
}

func doGET(t *testing.T, path string) *httptest.ResponseRecorder {
	t.Helper()
	r := initRouter()
	w := httptest.NewRecorder()
	req, err := http.NewRequest(http.MethodGet, path, nil)
	if err != nil {
		t.Fatalf("NewRequest: %v", err)
	}
	r.ServeHTTP(w, req)
	return w
}

func TestHomeOK(t *testing.T) {
	w := doGET(t, "/")
	if w.Code != http.StatusOK {
		t.Fatalf("GET / status=%d body=%q", w.Code, w.Body.String())
	}
	if !strings.Contains(w.Body.String(), "received") {
		t.Fatalf("GET / missing received: %q", w.Body.String())
	}
}

func TestUserPathParamOK(t *testing.T) {
	w := doGET(t, "/user/e2e")
	if w.Code != http.StatusOK {
		t.Fatalf("GET /user/e2e status=%d body=%q", w.Code, w.Body.String())
	}
	body := w.Body.String()
	if !strings.Contains(body, "Hello") || !strings.Contains(body, "e2e") {
		t.Fatalf("GET /user/e2e body=%q", body)
	}
}

func TestListStillRoutes(t *testing.T) {
	// Route must exist after remedia. Do not assert ls output — that is the sink.
	w := doGET(t, "/list")
	if w.Code != http.StatusOK {
		t.Fatalf("GET /list status=%d body=%q", w.Code, w.Body.String())
	}
}

func TestUnknownRoute404(t *testing.T) {
	w := doGET(t, "/no-such-route")
	if w.Code != http.StatusNotFound {
		t.Fatalf("GET /no-such-route status=%d body=%q", w.Code, w.Body.String())
	}
}
