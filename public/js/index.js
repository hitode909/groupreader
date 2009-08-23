$(function() {
      $('form').submit(
          function() {
              var name = $("input").val();
              console.log(name);
              if (!name) return false;
              location.href = '/group/' + name;
              return false;
          });
  });