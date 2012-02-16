var tracker;

$(document).ready(function() {
  tracker = new TrackerKeeper();
  // if (window.localStorage) {
  //   if (window.localStorage["token"] && window.localStorage["name"]) {
  //     $(".main").html("<em>Loading</em>");
  //     $.ajax({
  //       type:'POST',
  //       data:"ajax=true&name="+window.localStorage["name"]+"&token="+window.localStorage["token"],
  //       url:'/login',
  //       success:function(data) {
  //         $(".main").html(data);
  //       }
  //     });
  //   }
  // }
  $("a.name").live('click',function() {
    tracker.loadStory(
      $(this).parents(".story").attr("data-project-id"),
      $(this).parents(".story").attr("data-story-id")
    );
    return false;
  });
  $(".story .action").live('click',function() {
    tracker.updateStatus(
      $(this).parents(".story").attr("data-project-id"),
      $(this).parents(".story").attr("data-story-id"),
      $(this).attr('data-action')
    );
    return false;
  });
  $("#refresh").live('click',function() {
    tracker.reloadStories();
  })
});

var TrackerKeeper = function() {
  this.login = (function() {
    $.ajax({
      type:'POST',
      data:$("#login").serialize(),
      url:'/login',
      success:function(data) {
        window.localStorage["name"] = $("#name").val()
        window.localStorage["token"] = $("#token").val()
        $(".main").html(data);
      }
    });
    return false;
  });
  this.reloadStories = (function() {
    $.ajax({
      type:'GET',
      data:"ajax=true",
      url:'/refresh',
      success:function(data) {
        $(".main").html(data);
      }
    });
    return false;
  });
  this.loadStory = (function(projectId, storyId) {
    var description = $("div [data-story-id="+storyId+"] .description")
    if (description.size() > 0) {
      if (description.html() == "") {
        $.ajax({
          type:'GET',
          data:'storyId='+storyId+'&projectId='+projectId,
          url:'/load',
          success:function(data) {
            description.html(data).show();
          }
        });
      } else {
        description.toggle();
      }
    }
  });

  this.updateStatus = (function(projectId, storyId, action) {
    var project = $("div [data-story-id="+storyId+"]")
    if (project.size() > 0) {
      $.ajax({
        type:'POST',
        data:'storyId='+storyId+'&projectId='+projectId+'&action='+action,
        url:'/update',
        success:function(data) {
          project.children(".actions").html(data);
        }
      });
    }
  });
}