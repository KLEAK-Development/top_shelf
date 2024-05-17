class PostTodo {
  final String title;

  const PostTodo(this.title);

  factory PostTodo.fromJson(Map<String, dynamic> json) {
    if (json case {'title': final String title}) {
      return PostTodo(title);
    } else {
      throw FormatException('Unexpected JSON');
    }
  }
}
