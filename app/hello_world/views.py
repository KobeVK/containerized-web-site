from django.shortcuts import render

def get_name(request):
    name = request.GET.get('name', 'world')
    return render(request, 'index.html', {'name': name})
