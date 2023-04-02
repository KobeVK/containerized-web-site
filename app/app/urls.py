# from django.contrib import admin
from django.urls import path
from hello_world import views


urlpatterns = [
    path('', views.get_name, name='get_name')
]